#!/bin/bash

# set $cluster1 and $cluster2 kubeconfig
source ~/lab_clusters.sh

# function to bootstrap spire
function bootstrap_spire_federation() {
    local fed1=$1; shift
    local fed2=$1; shift
    local fed1_spire_pod_name=$1; shift
    local fed2_spire_pod_name=$1; shift
    local fed1_spire_container_name=$1; shift
    local fed2_spire_container_name=$1; shift
    local trust_domain=$1; shift

    kubectl exec -it \
        --kubeconfig ${fed1} \
        -n spire "${fed1_spire_pod_name}" \
        -c "${fed1_spire_container_name}" -- \
            bin/spire-server bundle show \
            -registrationUDSPath ../../run/spire/sockets/registration.sock \
            -format spiffe | \
                kubectl exec -i \
                    --kubeconfig ${fed2} \
                    -n spire "${fed2_spire_pod_name}" \
                    -c "${fed2_spire_container_name}" -- \
                        bin/spire-server bundle set \
                        -registrationUDSPath ../../run/spire/sockets/registration.sock \
                        -format spiffe \
                        -id "spiffe://${trust_domain}"

}

# Bootstrap spire bundles
echo "Bootstrap certificate from cluster1 to cluster2"
bootstrap_spire_federation $cluster1 $cluster2 "spire-server-0" "spire-server-0" "spire-server" "spire-server" "cluster1.com"
echo "Bootstrap certificate from cluster2 to cluster1"
bootstrap_spire_federation $cluster2 $cluster1 "spire-server-0" "spire-server-0" "spire-server" "spire-server" "cluster2.com"
