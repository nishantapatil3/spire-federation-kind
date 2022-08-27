.PHONY: build

build:
	${PWD}/1-build.sh

docker-build:
	docker build . -f docker/Dockerfile.broker-webapp -t docker.io/nishantapatil3/broker-webapp:latest
	docker build . -f docker/Dockerfile.stock-quotes-service -t docker.io/nishantapatil3/stock-quotes-service:latest

clean:
	rm -rf build
