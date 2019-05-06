# openldap-alpine
Openldap Docker Image Based on Alpine Linux


# Test pbkdf2
```
 slappasswd -o module-load=pw-pbkdf2.so -h {PBKDF2-SHA512} -s secret
```

# LDAP folder

# .env

| Variable | Sample Value | Description |
| :----------- | :------------- | :----------------- |
|SLAPD_SUFFIX | dc=example,dc=org | |
|SLAPD_ORGANIZATION | Example | |
|SLAPD_DOMAIN|example||
|SLAPD_ROOTDN|cn=root,dc=example,dc=org||
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
