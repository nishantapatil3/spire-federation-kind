#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

(cd src/broker-webapp && CGO_ENABLED=0 GOOS=linux go build -v -o $DIR/docker/broker-webapp/broker-webapp)
(cd src/stock-quotes-service && CGO_ENABLED=0 GOOS=linux go build -v -o $DIR/docker/stock-quotes-service/stock-quotes-service)

echo "Done"

docker build docker/broker-webapp -t nishantapatil3/broker-webapp:latest
docker build docker/stock-quotes-service -t nishantapatil3/stock-quotes-service:latest

docker push nishantapatil3/broker-webapp:latest
docker push nishantapatil3/stock-quotes-service:latest
