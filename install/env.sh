#!/bin/bash

# Latest SEFK release (2026-11-18). Gateway API is derived from the go.mod chain, not guessed:
#   SEFK 2.4.1 -> kgateway OSS v2.5.1 -> Gateway API v1.7.0
export ENT_KGATEWAY_VERSION="2.4.1"
export K8S_GW_API_VERSION="v1.7.0"

# The portal chart is versioned in lockstep with SEFK.
export PORTAL_VERSION="$ENT_KGATEWAY_VERSION"

export ENT_KGATEWAY_HELM_VALUES_FILE="ent-kgateway-helm-values.yaml"
export ENT_KGATEWAY_SYSTEM_NAMESPACE="kgateway-system"
export PORTAL_NAMESPACE="kgateway-system"

# Namespace holding the reproducer's routes, ApiDocs, ApiProducts and backends.
export REPRO_NAMESPACE="portal-repro"

# Dedicated kind cluster and kubeconfig, so ~/.kube/config and other clusters stay untouched.
export KIND_CLUSTER_NAME="gg-2631"
export KUBECONFIG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.kubeconfig"
export KUBE_CONTEXT="kind-${KIND_CLUSTER_NAME}"
