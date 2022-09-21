#!/bin/bash

mkdir -p build
(cd src/broker-webapp && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build && mv broker-webapp ../../build/)
(cd src/stock-quotes-service && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build && mv stock-quotes-service ../../build/)

echo "**** Finished building binaries ****"

for entry in "${PWD}"/build/*
do
  echo "$entry"
done