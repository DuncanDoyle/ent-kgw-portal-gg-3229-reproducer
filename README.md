# Portal: stitching ignores HTTPRoute match precedence

Reproducer for [solo-io/gloo-gateway#3229](https://github.com/solo-io/gloo-gateway/issues/3229). Found while looking for a workaround for [#2631](https://github.com/solo-io/gloo-gateway/issues/2631) (no operation-level `exclude` on the v2 ApiProduct).

SEFK Portal publishes an operation in the stitched ApiDoc when an HTTPRoute rule routes to it. To exclude a single operation without listing every other one, you would combine a catch-all rule (`PathPrefix /`) with a more specific "shadow" rule for the excluded operation. At the gateway the shadow rule wins, as Gateway API precedence requires. **Stitching ignores that precedence.** Each rule is projected on its own, so the catch-all still publishes the excluded operation. Only an explicit allowlist (case A) works.

## Versions

| Component | Version |
|---|---|
| Solo Enterprise for kgateway (+ portal charts) | 2.4.1 |
| kgateway OSS | v2.5.1 |
| Gateway API | v1.7.0 |
| Built and run | 2026-11-19 |

## Cases

Every ApiDoc describes `GET /person`, `GET /address`, `GET /number` and `GET /lineitems`. The goal is to publish everything except `GET /number`.

| Case | Route | Gateway `GET /number` | Stitched spec (observed) | Correct? |
|---|---|---|---|---|
| A | allowlist: Exact match per wanted operation | 404, no route | person, address, lineitems | ✅ |
| B | `/` + shadow rule without `backendRefs` | 500 | all four | ❌ |
| C | `/` + shadow rule with DirectResponse 404 | 404 | all four | ❌ |
| D | `/` + shadow rule to a Service without an ApiDoc | 200 from `sink` | all four | ❌ |
| E | `/` + shadow rule to a Service with its own ApiDoc | 200 from `number-v2` | all four, `/number` from **case-e**. `number-v2-doc` is dropped with a "conflicting path" warning | ❌ |

B, C and D publish an operation the gateway never sends to that backend. E is worse and has nothing to do with excluding. A plain "route this one path elsewhere" setup publishes the wrong backend's operation and drops the backend that actually serves it. The version stays `Ready=True` in every case; E adds a warning.

Full output: [`test-output.txt`](test-output.txt).

## Root cause (from source, tag `2.4.1`)

- `internal/portal/apiproduct/route_rule_apidoc.go`: `resolveApiDocForRule` returns nil for a rule without `backendRefs`. Rules with a DirectResponse, or with no backend at all, are therefore never considered (B, C).
- Each remaining rule becomes its own `ruleApiDoc`. `projectSchema` (`stitching.go`) projects it against that rule's matches only, and `mergePaths` unions the results. Nothing checks whether a more specific match in another rule of the same route takes the request first (B–E).
- In E both rules produce `GET /number`. `detectPathConflicts` keeps the first one (rule 0, the catch-all) and drops the doc that is actually routed.

## Reproduce

Run from bash. `install/env.sh` points `KUBECONFIG` at a project-local `.kubeconfig`, so `~/.kube/config` is untouched.

```
export ENT_KGATEWAY_LICENSE_KEY=<your-key>
cd install
./create-kind-cluster.sh              # kind cluster gg-2631
./install-ent-kgateway-with-helm.sh
./install-portal-postgres.sh
./install-portal-with-helm.sh
./setup.sh                            # gateway, echo backend, routes, ApiDocs, ApiProducts
./setup-portal.sh                     # Portal CR
cd ..
./test.sh
```

## Teardown

```
kind delete cluster --name gg-2631 --kubeconfig .kubeconfig
```
