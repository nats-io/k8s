#!/bin/bash

# set -exuo pipefail
set -euo pipefail

NATS_BOOTSTRAP_YML=${DEFAULT_NATS_BOOTSTRAP_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/b19d5aac2bc37b09f75f9d4410d6c3806f410ef3/nats-bootstrap-sa.yaml}
NATS_SETUP_IMAGE=${DEFAULT_NATS_SETUP_IMAGE:=synadia/nats-setup:latest}

kubectl apply -f $NATS_BOOTSTRAP_YML
kubectl run nats-setup --generator=run-pod/v1 --image-pull-policy=Always --serviceaccount=nats-setup --image=$NATS_SETUP_IMAGE --restart=Never
kubectl wait --for=condition=Ready pod/nats-setup --timeout=30s
kubectl exec nats-setup -- nats-setup.sh $@
kubectl cp nats-setup:/nsc nsc
kubectl delete -f $NATS_BOOTSTRAP_YML
kubectl delete pod nats-setup --grace-period=0 --force
