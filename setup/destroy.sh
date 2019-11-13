#!/bin/bash

set -x

kubectl delete sts nats
kubectl delete sts prometheus-nats-prometheus
kubectl delete sts prometheus-nats-surveyor
kubectl delete deployment/nats-surveyor
kubectl delete deployment/nats-surveyor-grafana
kubectl delete deployment/prometheus-operator
kubectl delete secrets nats-sys-creds 
kubectl delete secrets prometheus-nats-prometheus
kubectl delete secrets prometheus-nats-surveyor
kubectl delete prometheuses nats-prometheus
kubectl delete prometheuses nats-surveyor
kubectl delete cm nats-accounts
kubectl delete cm nats-config
kubectl delete svc nats
kubectl delete svc grafana
kubectl delete svc nats-surveyor
kubectl delete svc nats-prometheus
kubectl delete svc nats-surveyor-prom
kubectl delete svc prometheus
kubectl delete svc prometheus-operator
