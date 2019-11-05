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
kubectl apply -f https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-server-v2-external.yml

# Install Prometheus Operator
kubectl apply -f https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/prometheus-operator.yml

# Create Prometheus instance for NATS usage
kubectl apply -f https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-prometheus.yml

# Deploy NATS Surveyor
kubectl apply -f https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-surveyor.yml

# Deploy NATS Surveyor Grafana instance
kubectl apply -f https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-surveyor-grafana.yml
