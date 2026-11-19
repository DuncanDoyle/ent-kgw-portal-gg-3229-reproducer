#!/bin/bash

# Versions come from env.sh (SEFK + the Gateway API version paired with it).
source ./env.sh

if [ -z "$ENT_KGATEWAY_LICENSE_KEY" ]
then
   echo "Solo Enterprise for Kgateway License Key not specified. Please configure the environment variable 'ENT_KGATEWAY_LICENSE_KEY' with your Solo Enterprise for kgateway License Key."
   exit 1
fi

export ENT_KGATEWAY_CRDS_URL="oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/enterprise-kgateway-crds"
export ENT_KGATEWAY_URL="oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/enterprise-kgateway"

#----------------------------------------- Install Gloo Gateway with K8S Gateway API support -----------------------------------------

printf "\nApply K8S Gateway CRDs ....\n"
# Note: --server-side is a workaround. If not applied, the HTTPRoute CRD will not install.
kubectl --context "$KUBE_CONTEXT" apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/$K8S_GW_API_VERSION/experimental-install.yaml

printf "\nInstall Solo Enterprise for Kgateway CRDs ....\n"
helm --kube-context "$KUBE_CONTEXT" upgrade --install enterprise-kgateway-crds $ENT_KGATEWAY_CRDS_URL \
    --version $ENT_KGATEWAY_VERSION \
    --namespace $ENT_KGATEWAY_SYSTEM_NAMESPACE \
    --create-namespace \
    --set installExtAuthCRDs=true \
    --set installRateLimitCRDs=true \
    --set installEnterpriseListenerSetCRD=true

printf "\nInstall Solo Enterprise for Kgateway ...\n"
helm --kube-context "$KUBE_CONTEXT" upgrade --install enterprise-kgateway $ENT_KGATEWAY_URL \
    --version $ENT_KGATEWAY_VERSION \
    --namespace $ENT_KGATEWAY_SYSTEM_NAMESPACE \
    --create-namespace \
    --set-string licensing.licenseKey=$ENT_KGATEWAY_LICENSE_KEY \
    -f $ENT_KGATEWAY_HELM_VALUES_FILE
