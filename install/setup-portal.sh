#!/bin/bash

source ./env.sh

pushd ..

# The ReferenceGrant must exist before the Portal, or the first reconcile rejects the cross-namespace refs.
printf "\nDeploy Reference Grant (Portal -> ApiProduct) ...\n"
kubectl --context "$KUBE_CONTEXT" apply -f referencegrants/portal-to-apiproduct-rg.yaml

printf "\nDeploy PortalParameters and Portal ...\n"
kubectl --context "$KUBE_CONTEXT" apply -f portal/portal-parameters.yaml
kubectl --context "$KUBE_CONTEXT" apply -f portal/portal.yaml

popd
