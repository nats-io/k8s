#!/bin/sh

set -eu

NATS_K8S_VERSION=${DEFAULT_NATS_K8S_VERSION:=https://raw.githubusercontent.com/nats-io/k8s/93c2a213bd26791fda29da2b7238e3f3b1ca36e1}
NATS_BOOTSTRAP_YML=${DEFAULT_NATS_BOOTSTRAP_YML:=$NATS_K8S_VERSION/setup/bootstrap-policy.yml}
NATS_SETUP_IMAGE=${DEFAULT_NATS_SETUP_IMAGE:=synadia/nats-setup:0.1.6}

# Apply policy required to be able to create the resources.
kubectl apply -f "$NATS_BOOTSTRAP_YML"

# Run nats-setup container containing the latest set of manifests.
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nats-setup
spec:
  restartPolicy: Never
  serviceAccountName: nats-setup
  containers:
    - name: nats-setup
      image: $NATS_SETUP_IMAGE
      imagePullPolicy: Always
EOF

# Wait for the setup container to start or bail.
kubectl wait --for=condition=Ready pod/nats-setup --timeout=50s

# Pass the custom parameters to the nats-setup container image.
kubectl exec nats-setup -- nats-setup.sh "$@"

# Get a local copy of the nsc directory with the accounts.
kubectl cp nats-setup:/nsc nsc

# Remove the required policy for setup purposes.
kubectl delete -f "$NATS_BOOTSTRAP_YML"

# Remove the setup pod.
kubectl delete pod nats-setup --grace-period=0 --force
