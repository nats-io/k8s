#!/bin/sh

echo "Cleaning up..."

kubectl delete sts nats
kubectl delete sts stan
kubectl delete sts prometheus-nats-prometheus
kubectl delete sts prometheus-nats-surveyor
kubectl delete deployment/nats-surveyor
kubectl delete deployment/nats-surveyor-grafana
kubectl delete deployment/prometheus-operator
kubectl delete pod nats-box
kubectl delete secrets nats-sys-creds
kubectl delete secrets nats-test-creds
kubectl delete secrets nats-test2-creds
kubectl delete secrets stan-creds
kubectl delete secrets prometheus-nats-prometheus
kubectl delete secrets prometheus-nats-surveyor
kubectl delete prometheuses nats-prometheus
kubectl delete prometheuses nats-surveyor
kubectl delete cm nats-accounts
kubectl delete cm nats-config
kubectl delete svc nats
kubectl delete svc stan
kubectl delete svc grafana
kubectl delete svc nats-surveyor
kubectl delete svc nats-prometheus
kubectl delete svc nats-surveyor-prometheus
kubectl delete svc prometheus
kubectl delete svc prometheus-operator
kubectl delete secret nats-ca
kubectl delete secret nats-server-tls
kubectl delete secret nats-client-tls

