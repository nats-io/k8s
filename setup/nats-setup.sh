#!/bin/sh
set -eu

NATS_SERVER_YML=${DEFAULT_NATS_SERVER_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-server-v2-external.yml}

NATS_SERVER_TLS_YML=${DEFAULT_NATS_SERVER_TLS_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-server-v2-external.yml}

PROMETHEUS_OPERATOR_YML=${DEFAULT_PROMETHEUS_OPERATOR_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/prometheus-operator.yml}

NATS_PROMETHEUS_YML=${DEFAULT_NATS_PROMETHEUS_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-prometheus.yml}

NATS_SURVEYOR_YML=${DEFAULT_NATS_SURVEYOR_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-surveyor.yml}

NATS_GRAFANA_YML=${DEFAULT_NATS_GRAFANA_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-surveyor-grafana.yml}

CERT_MANAGER_YML=${DEFAULT_CERT_MANAGER_YML:=$(pwd)/nats-server/cert-manager.yaml}

NSC_DIR=${DEFAULT_NSC_DIR:=$(pwd)/nsc}

export NATS_CONFIG_HOME=$NSC_DIR/config

export NKEYS_PATH=$NSC_DIR/nkeys

export NSC_HOME=$NSC_DIR/accounts

create_creds() {
        mkdir -p $NKEYS_PATH
        mkdir -p $NSC_HOME
        mkdir -p $NATS_CONFIG_HOME

        nsc add operator --name KO

        # Create system account
        nsc add account --name SYS
        nsc add user --name sys

        # Create test account
        nsc add account --name TEST
        nsc add user --name test

        # Generate accounts resolver config using the preload config
        (
          cd $NATS_CONFIG_HOME
          nsc generate config --mem-resolver --sys-account SYS > resolver.conf
        )

        chown -R 1000:1000 $NSC_DIR
}

create_secrets() {
        kubectl create secret generic nats-sys-creds  --from-file $NSC_DIR/nkeys/creds/KO/SYS/sys.creds
        kubectl create configmap nats-accounts --from-file $NSC_DIR/config/resolver.conf
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

install_nats_server_with_auth() {
        kubectl apply --filename $NATS_SERVER_YML
}

install_nats_server_with_auth_and_tls() {
        kubectl apply --filename $CERT_MANAGER_YML
        kubectl apply --filename $NATS_SERVER_TLS_YML
}

install_cert_manager() {
        kubectl get ns cert-manager > /dev/null 2> /dev/null || {
                kubectl create namespace cert-manager
        }

        kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.11.0/cert-manager.yaml
}

show_usage() {
    echo "Usage: $0 [options]

    --without-tls             Setup the cluster without TLS enabled
    --without-auth            Setup the cluster without Auth enabled
    --without-surveyor        Skips installing NATS surveyor
    --without-cert-manager    Skips installing the cert manager componenrt
    "
}

main() {
        echo "
 #############################################
 #                                           #
 #  _   _    _  _____ ____   _  _____ ____   #
 # | \ | |  / \|_   _/ ___| | |/ ( _ ) ___|  #
 # |  \| | / _ \ | | \___ \ | ' // _ \___ \  #
 # | |\  |/ ___ \| |  ___) || . \ (_) |__) | #
 # |_| \_/_/   \_\_| |____(_)_|\_\___/____/  #
 #                                           #
 #############################################
"

        with_surveyor=true
        with_tls=true
        with_auth=true
        with_cert_manager=true

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
                        --without-cert-manager)
                                with_cert_manager=false
                                ;;
                        --without-auth)
                                with_auth=false
                                ;;
                        *)
                                echo "unknown flag: $1"
                                ;;
                esac
                shift
        done

	echo
	echo " +---------------------+---------------------+"
	echo " |                 OPTIONS                   |"
	echo " +---------------------+---------------------+"
        echo "         nats server   | true    "
        echo "         nats surveyor | $with_surveyor    "
        echo "         nats tls      | $with_tls    "
        echo "        setup auth     | $with_auth    "
        echo "         cert_manager  | $with_cert_manager    "
	echo " +-------------------------------------------+"

	echo 
        echo " +-------------------------------------------+"
        echo " | Installing NATS components...             |"
        echo " +-------------------------------------------+"
	echo 

        if [ $with_auth = true ]; then
                create_creds
                create_secrets
        fi

        if [ $with_cert_manager = true ]; then
                install_cert_manager
        fi

        if [ $with_tls = true ]; then
                install_nats_server_with_auth_and_tls
        else
                install_nats_server_with_auth
        fi

        if [ $with_surveyor = true ]; then
                install_nats_surveyor
        fi

        # Confirm setup by sending some messages using the system account.
        echo " +------------------------------------------+"
        echo " | Done. Enjoy your new NATS cluster!       |"
        echo " +------------------------------------------+"

}

main "$@"
