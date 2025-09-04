#!/bin/bash

# Build broker container
docker build --file src/broker-webapp/Dockerfile -t ghcr.io/nishantapatil3/broker-webapp:latest src/broker-webapp/

# Build stock-quotes container
docker build --file src/broker-webapp/Dockerfile -t ghcr.io/nishantapatil3/stock-quotes-service:latest src/stock-quotes-service/

# Push broker container
docker push ghcr.io/nishantapatil3/broker-webapp:latest

# Push stock-quotes container
docker push ghcr.io/nishantapatil3/stock-quotes-service:latest