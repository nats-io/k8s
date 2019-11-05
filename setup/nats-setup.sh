#!/bin/sh

export NKEYS_PATH=/nsc/nkeys
export NSC_HOME=/nsc/accounts
export NATS_CONFIG_HOME=/nsc/config
mkdir -p $NKEYS_PATH
mkdir -p $NSC_HOME
mkdir -p $NATS_CONFIG_HOME
nsc add operator --name KO
nsc add account --name SYS
nsc add user --name sys
nsc add account --name TEST
nsc add user --name test
(
  cd $NATS_CONFIG_HOME
  nsc generate config --mem-resolver --sys-account SYS > resolver.conf
)
chown -R 1000:1000 /nsc

kubectl create secret generic nats-sys-creds  --from-file /nsc/nkeys/creds/KO/SYS/sys.creds
kubectl create configmap nats-accounts --from-file /nsc/config/resolver.conf

# Install NATS Server
kubectl apply -f 'https://raw.githubusercontent.com/nats-io/nats.k8s/sts/nats-server/nats-server-v2-external.yml?token=AAAGMU3HLE3S3MWJBZRWYOK5ZI6IQ'

# Install Prometheus Operator
kubectl apply -f 'https://raw.githubusercontent.com/nats-io/nats.k8s/sts/nats-server/prometheus-operator.yml?token=AAAGMU2LN4MDGEOS3XSTBSK5ZI6PQ'

# Create Prometheus instance for NATS usage
kubectl apply -f 'https://raw.githubusercontent.com/nats-io/nats.k8s/sts/nats-server/nats-prometheus.yml?token=AAAGMU43WUQHUYIJKH2CS7S5ZI6RO'

# Deploy NATS Surveyor
kubectl apply -f 'https://raw.githubusercontent.com/nats-io/nats.k8s/sts/nats-server/nats-surveyor.yaml?token=AAAGMU756KJWFQVKGXVBGWS5ZI6TK'

# Deploy NATS Surveyor Grafana instance
kubectl apply -f 'https://raw.githubusercontent.com/nats-io/nats.k8s/sts/nats-server/nats-surveyor-grafana.yaml?token=AAAGMU5R46ML2KBTYBTQZWC5ZI6TS'
