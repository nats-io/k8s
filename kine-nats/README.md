# kine-nats

This directory contains instructions and scripts for creating a local testing environment against [kine](https://github.com/k3s-io/kine/) with a NATS JetStream backend.

## Prerequisites

```bash
# clone the kine repo into this directory
git clone git@github.com:k3s-io/kine.git

# install python dependencies for load tests
pip install kubernetes termplotlib
```

## Run Development Stack

```bash
# start docker compose stack
docker compose up -d --build

# wait until k3s has started
# then copy the kubeconfig to current directory
docker compose cp k3s:/etc/rancher/k3s/k3s.yaml ./k3s.yaml
export KUBECONFIG="$(pwd)/k3s.yaml"

# run load test
./kine/scripts/test-load
```

## Destroy Stack

```bash
# destroy docker compose stack
docker compose down -v
```

## Run Connection Test

```bash
cd kine
./scripts/build
./scripts/package
. ./scripts/test-helpers
. ./scripts/test-run-jetstream
```
