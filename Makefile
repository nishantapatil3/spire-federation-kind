.PHONY: build

build:
	${PWD}/1-build.sh

docker-build:
	docker build . -f docker/Dockerfile -t docker.io/nishantapatil3/spire-federation-kind:latest

clean:
	rm -rf build
