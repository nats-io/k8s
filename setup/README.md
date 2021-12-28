# NATS Setup

The `setup.sh` script found at the root of the repository will run a
`nats-setup` container image which will deploy a secure NATS cluster
of three with allowed external access.

### Running the script locally

By default, the script will use the manifests found in the Github
repo, in case you want to try a change and run the script locally then
you should override the defaults via the environment variables defined
in the `.env` file at the root of the repository:

```
git clone https://github.com/nats-io/k8s/
source .env
./setup/nats-setup.sh -h

Usage: ./setup/nats-setup.sh [options]

    -n, --namespace <namespace>  Setup the cluster in the specified namespace
    --without-tls                Setup the cluster without TLS enabled
    --without-auth               Setup the cluster without Auth enabled
    --without-surveyor           Skips installing NATS surveyor
    --without-cert-manager       Skips installing the cert manager component
    --without-nats-streaming     Setup the cluster without NATS Streaming
```

### Building nats-setup container image

```sh
git clone https://github.com/nats-io/k8s/
cd setup
docker build -t synadia/nats-setup:latest .
```
