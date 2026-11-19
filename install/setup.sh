#!/bin/bash

source ./env.sh

pushd ..

# Gateway
kubectl --context "$KUBE_CONTEXT" create namespace ingress-gw --dry-run=client -o yaml | kubectl --context "$KUBE_CONTEXT" apply -f -
kubectl --context "$KUBE_CONTEXT" apply -f gateways/gw-parameters.yaml
kubectl --context "$KUBE_CONTEXT" apply -f gateways/gw.yaml

# The Gateway only accepts routes from namespaces carrying this label.
kubectl --context "$KUBE_CONTEXT" create namespace $REPRO_NAMESPACE --dry-run=client -o yaml | kubectl --context "$KUBE_CONTEXT" apply -f -
kubectl --context "$KUBE_CONTEXT" label namespace $REPRO_NAMESPACE --overwrite shared-gateway-access="true"

printf "\nDeploy echo backend ...\n"
kubectl --context "$KUBE_CONTEXT" apply -f apis/echo.yaml

printf "\nDeploy DirectResponse (case C) ...\n"
kubectl --context "$KUBE_CONTEXT" apply -f policies/direct-response.yaml

printf "\nDeploy HTTPRoutes ...\n"
kubectl --context "$KUBE_CONTEXT" apply -f routes/httproutes.yaml

# ApiDocs before ApiProducts, so the first ApiProduct reconcile already sees them.
printf "\nDeploy ApiDocs ...\n"
kubectl --context "$KUBE_CONTEXT" apply -f apidocs/apidocs.yaml

printf "\nDeploy ApiProducts ...\n"
kubectl --context "$KUBE_CONTEXT" apply -f apiproducts/apiproducts.yaml

printf "\nWait for echo backend ...\n"
kubectl --context "$KUBE_CONTEXT" -n $REPRO_NAMESPACE rollout status deployment/echo --timeout=90s

popd
