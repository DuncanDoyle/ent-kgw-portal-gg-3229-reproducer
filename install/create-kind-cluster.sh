#!/bin/bash

source ./env.sh

# Writes the cluster's credentials to the project-local .kubeconfig only.
kind create cluster --name "$KIND_CLUSTER_NAME" --kubeconfig "$KUBECONFIG"

# LoadBalancer IPs for the Gateway Service (cloud-provider-kind must be running on the host),
# or use port-forwarding as test.sh does by default.
