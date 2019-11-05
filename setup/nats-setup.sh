#!/bin/sh
set -eu

get_nsc_creds() {
	export NKEYS_PATH=/nsc/nkeys
	export NSC_HOME=/nsc/accounts
	export NATS_CONFIG_HOME=/nsc/config

	mkdir --parents $NKEYS_PATH
	mkdir --parents $NSC_HOME
	mkdir --parents $NATS_CONFIG_HOME

	nsc add operator --name KO
	nsc add account --name SYS
	nsc add user --name sys
	nsc add account --name TEST
	nsc add user --name test
	(
	  cd $NATS_CONFIG_HOME
	  nsc generate config --mem-resolver --sys-account SYS > resolver.conf
	)

	chown --recursive 1000:1000 /nsc
}

set_secrets() {
	kubectl create secret generic nats-sys-creds  --from-file /nsc/nkeys/creds/KO/SYS/sys.creds
	kubectl create configmap nats-accounts --from-file /nsc/config/resolver.conf
}

install_nats_server() {
	kubectl apply -f https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-server-v2-external.yml
}

install_prometheus() {
	# Install Prometheus Operator
	kubectl apply -f https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/prometheus-operator.yml

	# Create Prometheus instance for NATS usage
	kubectl apply -f https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-prometheus.yml
}

install_nats_surveyor() {
	install_prometheus

	# Deploy NATS Surveyor
	kubectl apply -f https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-surveyor.yml

	# Deploy NATS Surveyor Grafana instance
	kubectl apply -f https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-surveyor-grafana.yml
}

main() {
	with_surveyor=true
	with_tls=true

	while [ ! $# -eq 0 ]; do
		case $1 in
			--skip-surveyor)
				with_surveyor=false
				;;
			--insecure)
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
	echo "install tls: $with_tls"

	install_nats_server

	if [ $with_surveyor = true ]; then
		install_nats_surveyor
	fi

	if [ $with_tls = true ]; then
		echo "tls support not implemented yet..."
	fi
}

main "$@"
