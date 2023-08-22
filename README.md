<img width="2487" alt="Screen Shot 2020-10-12 at 4 59 32 PM" src="https://user-images.githubusercontent.com/26195/95800603-99d95f00-0cac-11eb-968b-f3e4dde3ff8d.png">

[![License][License-Image]][License-Url]

[License-Url]: https://www.apache.org/licenses/LICENSE-2.0
[License-Image]: https://img.shields.io/badge/License-Apache2-blue.svg

# Running NATS on K8S

In this repository you can find several examples of how to deploy NATS, NATS Streaming 
and other tools from the NATS ecosystem on Kubernetes.

- [NATS Helm Chart](https://github.com/nats-io/k8s/tree/main/helm/charts/nats#jetstream)
- [NATS Surveyor Chart](https://github.com/nats-io/k8s/tree/main/helm/charts/surveyor)
- [NATS JetStream Controller Chart](https://github.com/nats-io/k8s/tree/main/helm/charts/nack)

## Getting started with NATS using Helm

In this repo you can find the Helm 3 based [charts](https://github.com/nats-io/k8s/tree/main/helm/charts) to install NATS.

```sh
> helm repo add nats https://nats-io.github.io/k8s/helm/charts/
> helm repo update

> helm repo list
NAME          	URL 
nats          	https://nats-io.github.io/k8s/helm/charts/

> helm install my-nats nats/nats
```

## License

Unless otherwise noted, the NATS source files are distributed
under the Apache Version 2.0 license found in the LICENSE file.
