#!/bin/sh

_escurl() { echo $1 | sed 's|/|%2F|g' ;}
_envsubst() { envsubst < $1 > /tmp/subst.ldif;}

host=$(hostname)
SLAPD_CONF_DIR=/etc/openldap/slapd.d
SLAPD_IPC_SOCKET=/run/openldap/ldapi
if [[ ! -d ${SLAPD_CONF_DIR} ]]; then
	FIRST_START=1
	DB_DUMP_FILE=/ldap/dump/dbdump.ldif
	SLAPD_CONF=/etc/openldap/slapd.conf
	if [[ ! -f ${SLAPD_CONF} ]];then
	 touch ${SLAPD_CONF}
	fi
	mkdir -p /run/openldap/

	echo "Configuring OpenLDAP via slapd.d"
	mkdir -p ${SLAPD_CONF_DIR}
	chmod -R 750 ${SLAPD_CONF_DIR}
	mkdir -p /var/lib/openldap/openldap-data
    chmod -R 750 /var/lib/openldap/openldap-data

	echo "SLAPD_ROOTDN = $SLAPD_ROOTDN"
	if [[ -z "$SLAPD_ROOTDN" ]]; then
		echo -n >&2 "Error: SLAPD_ROOTDN not set. "
		echo >&2 "Did you forget to add -e SLAPD_ROOTDN=... ?"
		exit 1
	fi
	if [[ -z "$SLAPD_ROOTPW" ]]; then
		echo -n >&2 "Error: SLAPD_ROOTPW not set. "
		echo >&2 "Did you forget to add -e SLAPD_ROOTPW=... ?"
		exit 1
	fi

	rootpw_hash=`slappasswd -o module-load=pw-pbkdf2.so -h {PBKDF2-SHA512} -s "${SLAPD_ROOTPW}"`

    ls -al $SLAPD_CONF
	# builtin schema
	cat <<-EOF > "$SLAPD_CONF"
	include /etc/openldap/schema/core.schema
	include /etc/openldap/schema/cosine.schema
	include /etc/openldap/schema/inetorgperson.schema
	include /etc/openldap/schema/ppolicy.schema
	EOF

	# user-provided schemas
	if [[ -d "/ldap/schema" ]] &&  [[ "$(ls -A '/ldap/schema')" ]]; then
		for f in /ldap/schema/*.schema ; do
			echo "Including custom schema $f"
			echo "include $f" >> "$SLAPD_CONF"
		done
	fi

    if [[ -d "/ldap/pki" ]]  &&  [[ "$(ls -A '/ldap/pki')" ]];then
        CA _CERT=/ldap/pki/ca_cert.pem
        SSL_KEY=/ldap/pki/key.pem
        SSL_CERT=/ldap/pki/cert.pem

        # user-provided tls certs
        echo "TLSCACertificateFile ${CA_CERT}" >>  "$SLAPD_CONF"
        echo "TLSCertificateFile ${SSL_CERT}" >>  "$SLAPD_CONF"
        echo "TLSCertificateKeyFile ${SSL_KEY}" >>  "$SLAPD_CONF"
        echo "TLSCipherSuite HIGH:-SSLv2:-SSLv3" >>  "$SLAPD_CONF"
    fi

    #rootpw $config_rootpw_hash
	cat <<-EOF >> "$SLAPD_CONF"
pidfile		/run/openldap/slapd.pid
argsfile	/run/openldap/slapd.args
modulepath  /usr/lib/openldap
moduleload  back_mdb.so
moduleload  pw-pbkdf2.so
database config
rootdn "gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth"
access to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by dn.base="$SLAPD_ROOTDN" manage by * break
database mdb
access to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage by dn.base="$SLAPD_ROOTDN" manage by * none
maxsize 1073741824
suffix "$SLAPD_SUFFIX"
rootdn "$SLAPD_ROOTDN"
rootpw $rootpw_hash
password-hash {PBKDF2-SHA512}
directory  /var/lib/openldap/openldap-data
	EOF


	echo "Generating configuration"
	slaptest -f ${SLAPD_CONF} -F ${SLAPD_CONF_DIR} -d ${SLAPD_LOG_LEVEL}
    chown -R ldap:ldap ${SLAPD_CONF_DIR}
    chown -R ldap:ldap /run/openldap/
    chown -R ldap:ldap /var/lib/openldap/openldap-data

    echo "Starting slapd for first configuration"
    slapd -h "ldap:/// ldapi://$(_escurl ${SLAPD_IPC_SOCKET})" -u ldap -g ldap -F ${SLAPD_CONF_DIR} -d ${SLAPD_LOG_LEVEL} &
    _PID=$!

	# handle race condition
	echo "Waiting for server ${_PID} to start..."
	let i=0
	while [[ ${i} -lt 60 ]]; do
		printf "."
		ldapsearch -Y EXTERNAL -H ldapi://$(_escurl ${SLAPD_IPC_SOCKET}) -s base -b '' >/dev/null 2>&1
		#ldapsearch -x -H ldap:/// -s base -b '' >/dev/null 2>&1
		test $? -eq 0 && break
		sleep 1
		let i=`expr ${i} + 1`
	done
	if [[ $? -eq 0 ]] ; then
	   echo "Server running an ready to be configured"
	else
	   echo "Oops, something went wrong and server may not be properly (pre) configured, check the logs!"
	fi

	echo "Adding additional config from /ldap/ldif/*.ldif"
	for f in /ldap/ldif/*.ldif ; do
		echo "> $f"
		_envsubst ${f}
		#ldapmodify -x -H ldap://localhost -w ${SLAPD_ROOTPW} -D ${SLAPD_ROOTDN} -f /tmp/subst.ldif
		ldapmodify -Y EXTERNAL -H ldapi://$(_escurl ${SLAPD_IPC_SOCKET}) -f /tmp/subst.ldif
	done

	if [[ -d /ldap/userldif ]] ; then
		echo "Adding user config from /ldap/userldif/*.ldif"
		for f in /ldap/userldif/*.ldif ; do
			echo "> $f"
			_envsubst ${f}
			#ldapmodify -x -H ldap://localhost -w ${SLAPD_ROOTPW} -D ${SLAPD_ROOTDN} -f $f
			ldapmodify -Y EXTERNAL -H ldapi://$(_escurl ${SLAPD_IPC_SOCKET}) -f /tmp/subst.ldif
		done
	fi
	echo "stopping server ${_PID}"
    kill -SIGTERM ${_PID}
    sleep 2
    if [[ -f "${DB_DUMP_FILE}" ]]; then
        echo "${DB_DUMP_FILE} found, restore DB from file..."
        _envsubst ${DB_DUMP_FILE}
        slapadd -l /tmp/subst.ldif -F ${SLAPD_CONF_DIR}
        restore_state=$?
        echo "restore finished with code ${restore_state}"

    fi
fi

if [[  -f "${SSL_KEY}"  ]] ; then
    echo "Starting LDAPS server..."
    slapd -h "ldaps:/// ldapi://$(_escurl ${SLAPD_IPC_SOCKET})"   -F ${SLAPD_CONF_DIR} -u ldap -g ldap -d "${SLAPD_LOG_LEVEL}"
else
    echo "Starting LDAP server..."
    slapd -h "ldap:/// ldapi://$(_escurl ${SLAPD_IPC_SOCKET})"  -F ${SLAPD_CONF_DIR} -u ldap -g ldap -d "${SLAPD_LOG_LEVEL}"
fi

exec "$@"
