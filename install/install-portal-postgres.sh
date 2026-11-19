#!/bin/bash

source ./env.sh

pushd ..

#----------------------------------------- Portal-Postgres -----------------------------------------

# The portal needs a store before it comes up. Throwaway reproducer, so Postgres uses emptyDir.
kubectl --context "$KUBE_CONTEXT" apply -f portal/portal-postgres-secret.yaml
kubectl --context "$KUBE_CONTEXT" apply -f portal/portal-postgres.yaml

printf "\nWait for Postgres ...\n"
kubectl --context "$KUBE_CONTEXT" -n $PORTAL_NAMESPACE rollout status deploy portal-postgres --timeout=180s

# The portal looks this secret up by this exact name.
kubectl --context "$KUBE_CONTEXT" apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: portal-postgres-secret
  namespace: $PORTAL_NAMESPACE
type: Opaque
stringData:
  host: "portal-postgres.$PORTAL_NAMESPACE.svc.cluster.local"
  port: "5432"
  username: "user"
  password: "pass"
  database: "db"
  sslmode: "disable"
EOF

popd
