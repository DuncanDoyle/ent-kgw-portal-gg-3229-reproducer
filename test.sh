#!/usr/bin/env bash
# Per case: the operations in the stitched ApiDoc, the ApiProduct version status, and what the
# gateway actually does with GET /number. The question: does the stitched spec agree with the gateway?
set -uo pipefail
cd "$(dirname "$0")"
source install/env.sh
K="kubectl --context $KUBE_CONTEXT"
NS=$REPRO_NAMESPACE

printf 'Waiting for stitched ApiDocs ...\n'
for _ in $(seq 1 60); do
  [ "$($K -n $NS get apidocs -o name 2>/dev/null | grep -c -- '-v1$')" -ge 5 ] && break
  sleep 2
done

# Data path through a port-forward to the Gateway Service.
$K -n ingress-gw port-forward svc/gw 18080:80 >/dev/null 2>&1 &
BODY=$(mktemp); PF=$!; trap "kill $PF 2>/dev/null; rm -f $BODY" EXIT; sleep 3

for c in a b c d e; do
  printf '\n=== CASE %s ===\n' "$(echo $c | tr a-z A-Z)"
  printf 'version status: '
  $K -n $NS get apiproduct case-$c \
    -o jsonpath='{range .status.versions[0].conditions[*]}{.type}={.status} ({.reason}) {.message}{"\n"}{end}' 2>/dev/null
  doc=$($K -n $NS get apidoc case-$c-v1 -o jsonpath='{.spec.source.stitched.content}' 2>/dev/null)
  if [ -z "$doc" ]; then
    printf 'stitched ApiDoc case-%s-v1 missing\n' $c
  else
    printf 'stitched operations:\n'
    # "summary" shows which source ApiDoc the operation came from.
    printf '%s' "$doc" | yq -o=json 2>/dev/null | jq -r '.paths // {} | to_entries[] | .key as $p | .value | to_entries[] | "  \(.key|ascii_upcase) \($p)  (\(.value.summary // "-"))"' \
      || printf '%s\n' "$doc"
  fi
  printf 'gateway GET /number: '
  curl -s -o "$BODY" -w '%{http_code}' -H "Host: case-$c.example.com" http://localhost:18080/number
  # Only echo responses are JSON; x-matched-rule tells the shadow rule apart from the catch-all.
  if jq -e . "$BODY" >/dev/null 2>&1; then
    printf ' via %s rule\n' "$(jq -r '.headers["x-matched-rule"] // "catch-all"' "$BODY")"
  else
    printf ' (%s)\n' "$(head -c 60 "$BODY")"
  fi
done

cat <<'EOF'

Expected: the stitched spec lists only operations the gateway routes to the ApiDoc's backend.
  A  person, address, lineitems                      gateway /number: 404 (no route)
  B  person, address, lineitems                      gateway /number: 500 (rule without backend)
  C  person, address, lineitems                      gateway /number: 404 (DirectResponse)
  D  person, address, lineitems                      gateway /number: 200 via shadow rule -> sink
  E  person, address, lineitems + number from number-v2   gateway /number: 200 via shadow rule -> number-v2
EOF
