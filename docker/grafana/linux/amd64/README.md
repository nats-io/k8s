# Makefile for building the NATS Surveyor docker image

In order to simplify the Kubernetes install of Surveyor, a nats-surveyor-grafana
docker image is built.  The makefile has `build` and `push` targets.

## Build

`$ make build` downloads the current dashboard from github and packages it up
in the containter.

## Push

`$ make push` pushes the image to the `synadia` docker organization.

