# nats.k8s

NATS Kubernetes Deployments

```
source .env
./setup/nats-setup.sh -h

Usage: ./setup/nats-setup.sh [options]

    --without-tls             Setup the cluster without TLS enabled
    --without-auth            Setup the cluster without Auth enabled
    --without-surveyor        Skips installing NATS surveyor
    --without-cert-manager    Skips installing the cert manager component
    --without-nats-streaming  Setup the cluster without NATS Streaming
```
