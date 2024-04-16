# from https://quay.io/repository/phasetwo/keycloak-crdb    
FROM quay.io/phasetwo/keycloak-crdb:latest as builder

# needed for cockroach support
ENV KB_DB=cockroach
ENV KC_TRANSACTION_XA_ENABLED=false
ENV KC_TRANSACTION_JTA_ENABLED=false

ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
WORKDIR /opt/keycloak

RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:0.0.0.0" -keystore conf/server.keystore
RUN /opt/keycloak/bin/kc.sh build
FROM quay.io/phasetwo/keycloak-crdb:latest
COPY --from=builder /opt/keycloak/ /opt/keycloak/
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ARG ADMIN
ARG ADMIN_PASSWORD

# from cockroach website
ARG DB_USERNAME
ARG DB_PASSWORD
# something like bepis-juniper-7455.g8z.gcp-us-east1.cockroachlabs.cloud
ARG DB_URL
# probably defaultdb
ARG DB_DATABASE
# probably 26257
ARG DB_PORT
# like https://cockroachlabs.cloud/clusters/fffffff-aaaa-bbbb-cccc-dddddddddd/cert
ARG CERT_PATH

# public
ARG DB_SCHEMA

# needed for cockroach support
ENV KB_DB=cockroach
ENV KC_TRANSACTION_XA_ENABLED=false
ENV KC_TRANSACTION_JTA_ENABLED=false

ENV KC_HTTP_RELATIVE_PATH=/auth
ENV PROXY_ADDRESS_FORWARDING=true
ENV KC_DB_URL_HOST=cockroach
ENV KC_DB_URL_PORT=$DB_PORT
ENV KC_DB_URL_DATABASE=$DB_DATABASE
ENV KC_DB_SCHEMA=$DB_SCHEMA
ENV KC_DB_USERNAME=$DB_USERNAME
ENV KC_DB_PASSWORD=$DB_PASSWORD
ENV KC_DB_URL_PROPERTIES='?'
ENV KC_HOSTNAME_STRICT='false'
ENV KC_HTTP_ENABLED='true'
ENV KC_PROXY='edge'
ENV KC_LOG_LEVEL=INFO
ENV KEYCLOAK_ADMIN=$ADMIN
ENV KEYCLOAK_ADMIN_PASSWORD=$ADMIN_PASSWORD
ENV KC_DB_URL=postgresql://${DB_USERNAME}:${DB_PASSWORD}@${DB_URL}:${DB_PORT}/${KC_DB_URL_DATABASE}?sslmode=verify-full

RUN mkdir -p $HOME/.postgresql
ADD '${CERT_PATH}' $Home/.postgresql/root.crt

ENTRYPOINT [“/opt/keycloak/bin/kc.sh”]
CMD [“start”,“–optimized”]