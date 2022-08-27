#!/bin/bash

mkdir -p build
(cd src/broker-webapp && CGO_ENABLED=0 GOOS=linux go build && mv broker-webapp ../../build/)
(cd src/stock-quotes-service && CGO_ENABLED=0 GOOS=linux go build && mv stock-quotes-service ../../build/)

echo "**** Finished building binaries ****"
