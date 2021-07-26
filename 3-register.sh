#!/bin/bash

# set $cluster1 and $cluster2 kubeconfig
echo "Setting clusters kubeconfig $(pwd)/lab_clusters.sh"
source $(pwd)/lab_clusters.sh

function register_spire_entry() {
    local kind_config=$1; shift
    local spire_server=$1; shift
    local spire_agent=$1; shift
    local workload_name=$1; shift
    local trust_domain=$1; shift
    local federates_with_arg=$1; shift

    echo "Registering workload: ${workload_name}"
    kubectl exec -it --kubeconfig ${kind_config} \
       -n spire "${spire_server}-0" \
       -c "${spire_server}" \
       -- bin/spire-server entry create \
           -registrationUDSPath ../../run/spire/sockets/registration.sock \
           -spiffeID "spiffe://${trust_domain}/${workload_name}" \
           -parentID "spiffe://${trust_domain}/${spire_agent}" \
           -selector "k8s:sa:${workload_name}-service-account" \
           ${federates_with_arg}
}

register_spire_entry $cluster1 "spire-server" "spire-agent" "server" "cluster1.com" "-federatesWith spiffe://cluster2.com"
register_spire_entry $cluster2 "spire-server" "spire-agent" "client" "cluster2.com" "-federatesWith spiffe://cluster1.com"
