#!/bin/sh
# docker entrypoint script
# configures and starts LDAP

if [ ! -d "/etc/openldap/slapd.d" ]; then

    # test for ldaps configuration
    LDAPS=true
    if [ -z "$KEY_FILE" ] || [ -z "$CERT_FILE" ] || [ -z "$CA_FILE" ]; then
      LDAPS=false
    fi


    # replace variables in slapd.conf
    SLAPD_CONF="/etc/openldap/slapd.conf"

    if [ "$LDAPS" = true ]; then
      sed -i "s~%CA_FILE%~$CA_FILE~g" "$SLAPD_CONF"
      sed -i "s~%KEY_FILE%~$KEY_FILE~g" "$SLAPD_CONF"
      sed -i "s~%CERT_FILE%~$CERT_FILE~g" "$SLAPD_CONF"
      if [ -n "$TLS_VERIFY_CLIENT" ]; then
        sed -i "/TLSVerifyClient/ s/demand/$TLS_VERIFY_CLIENT/" "$SLAPD_CONF"
      fi
    else
      # comment out TLS configuration
      sed -i "s~TLSCACertificateFile~#&~" "$SLAPD_CONF"
      sed -i "s~TLSCertificateKeyFile~#&~" "$SLAPD_CONF"
      sed -i "s~TLSCertificateFile~#&~" "$SLAPD_CONF"
      sed -i "s~TLSVerifyClient~#&~" "$SLAPD_CONF"
    fi

    sed -i "s~%ROOT_USER%~$ROOT_USER~g" "$SLAPD_CONF"
    sed -i "s~%SUFFIX%~$SUFFIX~g" "$SLAPD_CONF"
    sed -i "s~%ACCESS_CONTROL%~$ACCESS_CONTROL~g" "$SLAPD_CONF"

    # encrypt root password before replacing
    ROOT_PW=$(slappasswd -o module-load=pw-pbkdf2.so -h {PBKDF2-SHA512} -s "$ROOT_PW")
    sed -i "s~%ROOT_PW%~$ROOT_PW~g" "$SLAPD_CONF"

    # replace variables in organisation configuration
    ORG_CONF="/etc/openldap/organisation.ldif"
    sed -i "s~%SUFFIX%~$SUFFIX~g" "$ORG_CONF"
    sed -i "s~%ORGANISATION_NAME%~$ORGANISATION_NAME~g" "$ORG_CONF"

    # replace variables in user configuration
    USER_CONF="/etc/openldap/users.ldif"
    sed -i "s~%SUFFIX%~$SUFFIX~g" "$USER_CONF"
    sed -i "s~%USER_UID%~$USER_UID~g" "$USER_CONF"
    sed -i "s~%USER_GIVEN_NAME%~$USER_GIVEN_NAME~g" "$USER_CONF"
    sed -i "s~%USER_SURNAME%~$USER_SURNAME~g" "$USER_CONF"
    if [ -z "$USER_PW" ]; then USER_PW="password"; fi
    # encrypt user password
    USER_PW=$(slappasswd -o module-load=pw-pbkdf2.so -h {PBKDF2-SHA512} -s "$USER_PW")
    sed -i "s~%USER_PW%~$USER_PW~g" "$USER_CONF"
    sed -i "s~%USER_EMAIL%~$USER_EMAIL~g" "$USER_CONF"

    # add organisation and users to ldap (order is important)
    slapadd -l "$ORG_CONF"
    slapadd -l "$USER_CONF"

    mkdir -p /etc/openldap/slapd.d
    slaptest -f $SLAPD_CONF -F /etc/openldap/slapd.d
    rm $SLAPD_CONF

    # add any scripts in ldif
    for l in /ldif/modules/* /ldif/* /ldif/schema/* ; do
      case "$l" in
        *.ldif) echo "ENTRYPOINT: adding $l";
                envsubst < "$l" > "/tmp/out.ldif";
                slapadd -n0 -l "/tmp/out.ldif"
                ;;
        *)      echo "ENTRYPOINT: ignoring $l" ;;
      esac
    done

    #slapd -d "$LOG_LEVEL" -h "ldapi:///"


fi

if [ "$LDAPS" = true ]; then
  echo "Starting LDAPS"
  slapd -d "$LOG_LEVEL" -h "ldaps:///"
else
  echo "Starting LDAP"
  slapd -d "$LOG_LEVEL" -h "ldap:///"
fi

# run command passed to docker run
exec "$@"
