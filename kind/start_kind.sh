#!/bin/sh

mkdir -p $PWD/kubeconfigs

# kind-1
KINDCONFIG1="$PWD/kind/kind_config1.yaml"
KUBECONFIG1="$PWD/kubeconfigs/kind-1.kubeconfig"
kind create cluster --config $KINDCONFIG1
kind get kubeconfig --name kind-1 > $KUBECONFIG1
echo "kind-1 Kubeconfig generated - $KUBECONFIG1"

# kind-2
KINDCONFIG2="$PWD/kind/kind_config2.yaml"
KUBECONFIG2="$PWD/kubeconfigs/kind-2.kubeconfig"
kind create cluster --config $KINDCONFIG2
kind get kubeconfig --name kind-2 > $KUBECONFIG2
echo "kind-2 Kubeconfig generated - $KUBECONFIG2"
