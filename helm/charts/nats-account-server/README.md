# NATS Account Server

A simple HTTP server to host account JWTs for nats-server 2.0 account authentication.

NATS 2.0 introduced the concept of accounts to provide secure multi-tenancy through separate subject spaces. These accounts are configured with JWTs that encapsulate the account settings. User JWTs are used to authenticate. The nats-server can be configured to use local account information or to rely on an external, HTTP-based source for account JWTs.

## TL;DR;

```console
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm install my-nats-account-server nats/nats-account-server
```

## Basic Configuration

```yaml
accountserver:
  image: "synadia/nats-account-server:0.8.4"
  pullPolicy: IfNotPresent
```

## Storage

```yaml
store:
  type: file
  file:
    storageSize: 1Gi
```

## NATS Connection

NATS Server connection settings.

```yaml
nats:
  # NATS Service to which we can connect.
  url: "nats://nats:4222"

  # Credentials to connect to the NATS Server.
  credentials:
    secret:
      name: nats-sys-creds
      key: sys.creds
```

## Operator

Trusted Operator mode settings.

```yaml
operator:
  # Reference to the system account jwt.
  systemaccountjwt:
    configMap:
      name: nats-sys-jwt
      key: SYS.jwt
  
  # Reference to the Operator JWT.
  operatorjwt:
    configMap:
      name: operator-jwt
      key: KO.jwt
```
