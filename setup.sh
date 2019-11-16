#!/bin/sh

set -euo pipefail

NATS_K8S_VERSION=${DEFAULT_NATS_K8S_VERSION:=https://github.com/nats-io/k8s/blob/47b50c48403ceb3b13a0f4beed55c4467d25e2b3}
NATS_BOOTSTRAP_YML=${DEFAULT_NATS_BOOTSTRAP_YML:=$NATS_K8S_RELEASE/setup/bootstrap-policy.yml}
NATS_SETUP_IMAGE=${DEFAULT_NATS_SETUP_IMAGE:=synadia/nats-setup:latest}

kubectl apply -f $NATS_BOOTSTRAP_YML
kubectl run nats-setup --generator=run-pod/v1 --image-pull-policy=Always --serviceaccount=nats-setup --image=$NATS_SETUP_IMAGE --restart=Never
kubectl wait --for=condition=Ready pod/nats-setup --timeout=30s
kubectl exec nats-setup -- nats-setup.sh $@
kubectl cp nats-setup:/nsc nsc
kubectl delete -f $NATS_BOOTSTRAP_YML
kubectl delete pod nats-setup --grace-period=0 --force
