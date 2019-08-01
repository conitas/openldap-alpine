FROM alpine:3.10

RUN  apk update \
  && apk add gettext openldap openldap-clients openldap-back-mdb openldap-passwd-pbkdf2 openldap-overlay-memberof openldap-overlay-ppolicy openldap-overlay-refint \
  && rm -rf /var/cache/apk/* \
  && mkdir -p /ldap

EXPOSE 389
EXPOSE 636


COPY ldap/ /ldap/

COPY docker-entrypoint.sh /
RUN chmod +xr /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
