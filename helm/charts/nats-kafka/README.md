# nats-kafka

## TL;DR;

```
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm install -f my-values.yaml my-nats-kafka nats/nats-kafka
```

## Basic Configuration

This is an example configuration file you can pass to `-f`.

```yaml
natskafka:
  nats:
    servers:
      - "nats://1.2.3.4:4222"
  connect:
    - type: "NATSToKafka"
      brokers:
        - 1.2.3.4:9092
      id: whizz
      topic: bar
      subject: bang
    - type: "KafkaToNATS"
      brokers:
        - 1.2.3.4:9092
      id: foo
      topic: bar
      subject: baz
```
