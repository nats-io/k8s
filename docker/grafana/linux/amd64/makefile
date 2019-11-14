IMAGE := synadia/nats-surveyor-grafana
TAG := 0.0.1-alpha1
SURVEYOR_REPO := $(GOPATH)/src/github.com/nats-io/nats-surveyor
SURVEYOR_DASH := https://raw.githubusercontent.com/nats-io/nats-surveyor/master/docker-compose/grafana/provisioning/dashboards/nats-surveyor-dashboard.json
 
build:
	$(info Make: Building "$(TAG)" tagged images.)
	mkdir -p provisioning/dashboards
	curl $(SURVEYOR_DASH) --output provisioning/dashboards/nats-surveyor-dashboard.json
	cp -R $(SURVEYOR_REPO)/docker-compose/grafana/provisioning .
	@docker build -t $(IMAGE):$(TAG) .
	@docker tag $(IMAGE):$(TAG) $(IMAGE):latest

push:
	$(info Make: Pushing "$(TAG)" tagged image.)
	@docker push $(IMAGE):$(TAG)
	@docker push $(IMAGE):latest
