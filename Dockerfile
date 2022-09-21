FROM alpine:latest

COPY build/broker-webapp /usr/local/bin/broker-webapp
COPY build/stock-quotes-service /usr/local/bin/stock-quotes-service

WORKDIR /opt/spire
ENTRYPOINT []
