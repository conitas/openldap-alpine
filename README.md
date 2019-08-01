# openldap-alpine
Openldap Docker Image Based on Alpine Linux

Enabled modules:
- MDB Backend
- PBKDF2 Password Hash
- MemberOf Overlay 

# Data und Config Dirs
Configuration directory will be created on first run by entrypoint.sh and placed to `/etc/openldap/slapd.d`.

Data directory will be created on fist run by entrypoint.sh and placed to `/var/lib/openldap/openldap-data`.

Both should be mounted and backed up volumes e.g:

```
 docker run -it --rm  -p 8389:389 -v /opt/slapd-conf:/etc/openldap/slapd.d -v /opt/slapd-data:/var/lib/openldap/openldap-data itasgmbhde/openldap-alpine
```


# Test pbkdf2
```
 slappasswd -o module-load=pw-pbkdf2.so -h {PBKDF2-SHA512} -s secret
```

# LDAP folder
Here are some config options to enable during first startup. Environment variables may be used in ldif files and will be replaced before import.
## Default config
LDAP folder contains predefined configs (_ldif/_). Here are memberof and password policies preconfigured
## User config
User defined ldifs may be placed into (_userldif/_)    
 
## Custom schema 
Additional schema elements may be placed into _schema/_ folder.

## ssl config
here should be placed ssl certificates and keys for secured connection
- __ca_cert.pem__ - CA Certificate
- __cert.pem__ - Server Certificate 
- __key.pem__ - Server private key

## dump
Here can be placed a dump ldif to be restored on first start. Dump file should be named __dbdump.ldif__ and may be compressed with gzip (__dbdump.ldif.gz__).  

## Volumes
Mount external data volume to `/var/lib/openldap/openldap-data`.  

# .env

| Variable | Sample Value | Description |
| :----------- | :------------- | :----------------- |
|SLAPD_SUFFIX | dc=example,dc=org | Main suffix |
|SLAPD_ORGANIZATION | Example | Organization |
|SLAPD_DOMAIN|example| domain |
|SLAPD_ROOTDN|cn=root,dc=example,dc=org| Root DN|
|SLAPD_ROOTPW|Secret||
|SLAPD_LOG_LEVEL|any | see table 1|
|LDAPADD_DEBUG_LEVEL | 1 | see table 2 |

## Table 1: slapd/slaptest/slapcat loglevel
|Level|Keyword|Description|
|----|-----------|---------------|
|-1|	any|	enable all debugging|
|0|	 |	no debugging|
|1|	(0x1 trace)|	trace function calls|
|2|	(0x2 packets)|	debug packet handling|
|4|	(0x4 args)|	heavy trace debugging|
|8|	(0x8 conns)|	connection management|
|16|	(0x10 BER)|	print out packets sent and received|
|32|	(0x20 filter)|	search filter processing|
|64|	(0x40 config)|	configuration processing|
|128|	(0x80 ACL)|	access control list processing|
|256|	(0x100 stats)|stats log connections/operations/results|
|512|	(0x200 stats2)|	stats log entries sent|
|1024|	(0x400 shell)|	print communication with shell backends|
|2048|	(0x800 parse)|	print entry parsing debugging|
|16384|	(0x4000 sync)|	syncrepl consumer processing|
|32768|	(0x8000 none)|	only messages that get logged whatever log level is set|

## Table 2: ldapmodify/ldapadd debug level
|Level|Description|
|---|--------| 
|1|Trace|
|2|Packets|
|4|Arguments|
|32|Filters|
|128|Access control| 

