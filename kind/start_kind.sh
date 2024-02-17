#!/bin/sh

# kind-1
KINDCONFIG1="$PWD/kind_config1.yaml"
KUBECONFIG1="$PWD/kind-1.kubeconfig"
kind create cluster --config $KINDCONFIG1
kind get kubeconfig --name kind-1 > $KUBECONFIG1
echo "kind-1 Kubeconfig generated - $KUBECONFIG1"

# kind-2
KINDCONFIG2="$PWD/kind_config2.yaml"
KUBECONFIG2="$PWD/kind-1.kubeconfig"
kind create cluster --config $KINDCONFIG
kind get kubeconfig --name kind-1 > $KUBECONFIG2
echo "kind-1 Kubeconfig generated - $KUBECONFIG2"
