FROM alpine:3.9

RUN  apk update \
  && apk add gettext openldap openldap-back-mdb openldap-passwd-pbkdf2 openldap-overlay-memberof openldap-overlay-ppolicy openldap-overlay-refint \
  && rm -rf /var/cache/apk/*

EXPOSE 389
EXPOSE 636

RUN  mkdir -p /etc/openldap/modules \
  && mkdir -p /run/openldap \
  && mkdir -p /ldif
COPY scripts/* /etc/openldap/
COPY modules/* /etc/openldap/modules/
COPY modules/* /ldif/

COPY docker-entrypoint.sh /
RUN chmod +xr /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
