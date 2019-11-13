#!/bin/sh
set -eu

NATS_SERVER_YML=${DEFAULT_NATS_SERVER_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-server-v2-external.yml}

PROMETHEUS_OPERATOR_YML=${DEFAULT_PROMETHEUS_OPERATOR_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/prometheus-operator.yml}

NATS_PROMETHEUS_YML=${DEFAULT_NATS_PROMETHEUS_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-prometheus.yml}

NATS_SURVEYOR_YML=${DEFAULT_NATS_SURVEYOR_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-surveyor.yml}

NATS_GRAFANA_YML=${DEFAULT_NATS_GRAFANA_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-surveyor-grafana.yml}

NSC_DIR=${DEFAULT_NSC_DIR:=$(pwd)/nsc}

NATS_CONFIG_HOME=$NSC_DIR/config

export NKEYS_PATH=$NSC_DIR/nkeys

export NSC_HOME=$NSC_DIR/accounts

get_nsc_creds() {
	mkdir -p $NKEYS_PATH
	mkdir -p $NSC_HOME
	mkdir -p $NATS_CONFIG_HOME

	nsc add operator --name KO
	nsc add account --name SYS
	nsc add user --name sys
	nsc add account --name TEST
	nsc add user --name test
	(
	  cd $NATS_CONFIG_HOME
	  nsc generate config --mem-resolver --sys-account SYS > resolver.conf
	)

	chown -R 1000:1000 $NSC_DIR
}

set_secrets() {
	kubectl create secret generic nats-sys-creds  --from-file /nsc/nkeys/creds/KO/SYS/sys.creds
	kubectl create configmap nats-accounts --from-file /nsc/config/resolver.conf
}

install_nats_server() {
	kubectl apply --filename $NATS_SERVER_YML
}

install_prometheus() {
	# Install Prometheus Operator
	kubectl apply --filename $PROMETHEUS_OPERATOR_YML

	# Create Prometheus instance for NATS usage
	kubectl apply --filename $NATS_PROMETHEUS_YML
}

install_nats_surveyor() {
	install_prometheus

	# Deploy NATS Surveyor
	kubectl apply --filename $NATS_SURVEYOR_YML

	# Deploy NATS Surveyor Grafana instance
	kubectl apply --filename $NATS_GRAFANA_YML
}

install_tls() {
	kubectl apply --filename 
}

show_usage() {
    echo "Usage: $0 [options]
    --without-tls             Setup the cluster without TLS enabled
    --without-surveyor        Skips installing surveyor
    "
}

main() {
	with_surveyor=true
	with_tls=true

	while [ ! $# -eq 0 ]; do
		case $1 in
			-h)
				show_usage
				exit 0
				;;
			--without-surveyor)
				with_surveyor=false
				;;
			--without-tls)
				with_tls=false
				;;
			*)
				echo "unknown flag: $1"
				;;
		esac
		shift
	done

	echo "install nats server: true"
	echo "install nats surveyor: $with_surveyor"
	echo "install nats wth tls: $with_tls"

	get_nsc_creds
	set_secrets
	install_nats_server

	if [ $with_surveyor = true ]; then
		install_nats_surveyor
	fi

	if [ $with_tls = true ]; then
		install_tls
	fi
}

main "$@"
