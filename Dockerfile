FROM alpine:3.9

RUN  apk update \
  && apk add openldap openldap-back-mdb openldap-passwd-pbkdf2 openldap-overlay-memberof openldap-overlay-ppolicy \
  && rm -rf /var/cache/apk/*

EXPOSE 389
EXPOSE 636

RUN  mkdir -p /etc/openldap/modules \
  && mkdir -p /run/openldap/
COPY scripts/* /etc/openldap/
COPY modules/* /etc/openldap/modules/

COPY docker-entrypoint.sh /
RUN chmod +xr /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]