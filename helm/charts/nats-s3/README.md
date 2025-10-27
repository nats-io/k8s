# nats-kafka

## TL;DR;

```
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm install -f my-values.yaml my-nats-kafka nats/nats-kafka
```

## Configuration

The following example configurations can be set with `-f`.

**Basic**

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

**Monitoring**

```yaml
natskafka:
  monitoring:
    httpPort: 8222
  nats:
    servers:
      - "nats://1.2.3.4:4222"
  connect:
    - type: "NATSToKafka"
      brokers:
        - "1.2.3.4:9092"
      id: whizz
      topic: bar
      subject: bang
    - type: "KafkaToNATS"
      brokers:
        - "1.2.3.4:9092"
      id: foo
      topic: bar
      subject: baz
```

**Monitoring with TLS**

First, create a secret in Kubernetes with certs and keys.

```
kubectl create secret generic monitor-tls \
	--from-file=ca-cert.pem \
	--from-file=user-key.pem \
	--from-file=user-cert.pem
```

Then use the data in the secret in the configuration.

```yaml
natskafka:
  monitoring:
    httpsPort: 8222
    tls:
      secret: monitor-tls
      root: ca-cert.pem
      cert: user-cert.pem
      key: user-key.pem
  nats:
    servers:
      - "nats://1.2.3.4:4222"
  connect:
    - type: "NATSToKafka"
      brokers:
        - "1.2.3.4:9092"
      id: whizz
      topic: bar
      subject: bang
    - type: "KafkaToNATS"
      brokers:
        - "1.2.3.4:9092"
      id: foo
      topic: bar
      subject: baz
```

**Using Nats Credentials**

If you need a nats credential for authentication:

```yaml
natskafka:
  nats:
    servers:
      - "nats://1.2.3.4:4222"
    credentials:
      secret:
        name: nats-sys-creds
        key: sys.creds
  connect:
    - type: "NATSToKafka"
      brokers:
        - "1.2.3.4:9092"
      id: whizz
      topic: bar
      subject: bang
    - type: "KafkaToNATS"
      brokers:
        - "1.2.3.4:9092"
      id: foo
      topic: bar
      subject: baz
```
