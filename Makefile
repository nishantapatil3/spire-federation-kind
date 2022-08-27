.PHONY: build

build:
	${PWD}/1-build.sh

docker-build:
	docker build docker/broker-webapp -t docker.io/nishantapatil3/broker-webapp:latest
	docker build docker/stock-quotes-service -t docker.io/nishantapatil3/stock-quotes-service:latest

clean:
	rm docker/broker-webapp/broker-webapp
	rm docker/stock-quotes-service/stock-quotes-service
