#!/bin/sh

for cluster in $(kind get clusters); do
	echo "deleting.. $cluster"
	kind delete cluster --name $cluster
done