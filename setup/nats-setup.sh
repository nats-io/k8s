#!/bin/sh
set -eu

NATS_SERVER_YML=${DEFAULT_NATS_SERVER_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-server-v2-external.yml}

NATS_SERVER_TLS_YML=${DEFAULT_NATS_SERVER_TLS_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/31642afaed81575dc7ab218568beea1d5ae8c5d7/nats-server-v2-tls.yml}

NATS_SERVER_INSECURE_YML=${DEFAULT_NATS_SERVER_INSECURE_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-server-v2-external.yml}

PROMETHEUS_OPERATOR_YML=${DEFAULT_PROMETHEUS_OPERATOR_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/prometheus-operator.yml}

NATS_PROMETHEUS_YML=${DEFAULT_NATS_PROMETHEUS_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-prometheus.yml}

NATS_GRAFANA_YML=${DEFAULT_NATS_GRAFANA_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-surveyor-grafana.yml}

CERT_MANAGER_YML=${DEFAULT_CERT_MANAGER_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/7da870beb441fb9cfc00a4dede6d03f9eedc6973/cert-manager.yml}
CERT_MANAGER_RELEASE_YML=${DEFAULT_CERT_MANAGER_RELEASE_YML:=https://github.com/jetstack/cert-manager/releases/download/v0.11.0/cert-manager.yaml}

# With certs and creds, just auth no TLS, and plain examples.
NATS_BOX_AUTH_TLS_YML=${DEFAULT_NATS_BOX_AUTH_TLS_YML:=""}
NATS_BOX_AUTH_YML=${DEFAULT_NATS_BOX_AUTH_YML:=""}
NATS_BOX_YML=${DEFAULT_NATS_BOX_YML:=""}

NATS_SURVEYOR_TLS_YML=${DEFAULT_NATS_SURVEYOR_TLS_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-surveyor.yml}
NATS_SURVEYOR_YML=${DEFAULT_NATS_SURVEYOR_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-surveyor.yml}

NATS_STREAMING_AUTH_TLS_YML=${DEFAULT_NATS_STREAMING_AUTH_TLS_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/31642afaed81575dc7ab218568beea1d5ae8c5d7/nats-server-v2-tls.yml}
NATS_STREAMING_AUTH_YML=${DEFAULT_NATS_STREAMING_AUTH_YML:=https://gist.githubusercontent.com/wallyqs/3df5f9fb1a652d59344c65f0be04e48c/raw/643adae0e20351f79dcac1d2214d666c9842f309/nats-server-v2-external.yml}

NSC_DIR=${DEFAULT_NSC_DIR:=$(pwd)/nsc}

SKIP_NSC_DIR_CHOWN=${DEFAULT_SKIP_NSC_DIR_CHOWN:=false}

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
        nsc add user    --name sys

        # Create account for testing purposes
        nsc add account --name TEST
        nsc add user    --name test --allow-pubsub 'test.>'

        # Create account for STAN purposes
        nsc add account --name STAN
        nsc add user    --name stan

        # Generate accounts resolver config using the preload config
        (
          cd $NATS_CONFIG_HOME
          nsc generate config --mem-resolver --sys-account SYS > resolver.conf
        )

        if [ $SKIP_NSC_DIR_CHOWN != "true" ]; then
                chown -R 1000:1000 $NSC_DIR
        fi
}

create_secrets() {
        kubectl create secret generic nats-sys-creds   --from-file $NSC_DIR/nkeys/creds/KO/SYS/sys.creds
        kubectl create secret generic nats-test-creds  --from-file $NSC_DIR/nkeys/creds/KO/TEST/test.creds
        kubectl create secret generic stan-creds       --from-file $NSC_DIR/nkeys/creds/KO/STAN/stan.creds
        kubectl create configmap nats-accounts --from-file $NSC_DIR/config/resolver.conf
}

install_prometheus() {
        # Install Prometheus Operator
        kubectl apply --filename $PROMETHEUS_OPERATOR_YML

        # Create Prometheus instance for NATS usage
        kubectl apply --filename $NATS_PROMETHEUS_YML
}

install_nats_surveyor_components() {
        install_prometheus

        # Deploy NATS Surveyor Grafana instance
        kubectl apply --filename $NATS_GRAFANA_YML
}

install_nats_surveyor_with_tls() {
        kubectl apply --filename $NATS_SURVEYOR_TLS_YML
}

install_nats_surveyor() {
        kubectl apply --filename $NATS_SURVEYOR_YML
}

install_nats_server_with_auth() {
        kubectl apply --filename $NATS_SERVER_YML
}

install_nats_server_with_auth_and_tls() {
        kubectl apply --filename $CERT_MANAGER_YML
        kubectl apply --filename $NATS_SERVER_TLS_YML
}

install_insecure_nats_server() {
        kubectl apply --filename $NATS_SERVER_INSECURE_YML
}

install_cert_manager() {
        kubectl get ns cert-manager > /dev/null 2> /dev/null || {
                kubectl create namespace cert-manager
        }

        kubectl apply --validate=false -f $CERT_MANAGER_RELEASE_YML
}

install_nats_box_with_auth_and_tls() {
        kubectl apply --validate=false -f $NATS_BOX_AUTH_TLS_YML
}

install_nats_box_with_auth() {
        kubectl apply --validate=false -f $NATS_BOX_AUTH_YML
}

install_nats_box() {
        kubectl apply --validate=false -f $NATS_BOX_YML
}

install_nats_streaming_with_auth_and_tls() {
        kubectl apply --validate=false -f $NATS_STREAMING_AUTH_TLS_YML
}

install_nats_streaming_with_auth() {
        kubectl apply --validate=false -f $NATS_STREAMING_AUTH_YML
}

show_usage() {
    echo "Usage: $0 [options]

    --without-tls             Setup the cluster without TLS enabled
    --without-auth            Setup the cluster without Auth enabled
    --without-surveyor        Skips installing NATS surveyor
    --without-cert-manager    Skips installing the cert manager component
    --without-nats-streaming  Setup the cluster without NATS Streaming
"
}

main() {
        with_surveyor=true
        with_tls=true
        with_auth=true
        with_cert_manager=true
        with_stan=true

        while [ ! $# -eq 0 ]; do
                case $1 in
                        -h)
                                show_usage
                                exit 0
                                ;;
                        --without-surveyor)
                                # In case of deploying multiple clusters, only need a single instance.
                                with_surveyor=false
                                ;;
                        --without-tls)
                                with_tls=false
                                with_cert_manager=false
                                ;;
                        --without-cert-manager)
                                # In case cert manager has already been installed.
                                with_cert_manager=false
                                ;;
                        --without-auth)
                                with_auth=false

                                # Surveyor and NATS Streaming both require auth
                                with_surveyor=false
                                with_stan=false
                                ;;
                        --without-nats-streaming)
                                with_stan=false
                                ;;
                        --without-stan)
                                with_stan=false
                                ;;
                        *)
                                echo "unknown flag: $1"
                                ;;
                esac
                shift
        done


        echo
        echo "##############################################"
        echo "#                                            #"
        echo "#  _   _    _  _____ ____   _  _____ ____    #"
        echo "# | \ | |  / \|_   _/ ___| | |/ ( _ ) ___|   #"
        echo "# |  \| | / _ \ | | \___ \ | ' // _ \___ \   #"
        echo "# | |\  |/ ___ \| |  ___) || . \ (_) |__) |  #"
        echo "# |_| \_/_/   \_\_| |____(_)_|\_\___/____/   #"
        echo "#                                            #"
        echo "##############################################"
        echo
        echo " +---------------------+---------------------+"
        echo " |                 OPTIONS                   |"
        echo " +---------------------+---------------------+"
        echo "         nats server   | true                "
        echo "         nats surveyor | $with_surveyor      "
        echo "         nats tls      | $with_tls           "
        echo "        enable auth    | $with_auth          "
        echo "  install cert_manager | $with_cert_manager  "
        echo "      nats streaming   | $with_stan          "
        echo " +-------------------------------------------+"
        echo " |                                           |"
        echo " | Starting setup...                         |"
        echo " |                                           |"
        echo " +-------------------------------------------+"
        echo

        if [ $with_auth = true ]; then
                # Skip  if directory already exists
                [ ! -d "$NSC_DIR" ] && create_creds
                create_secrets
        fi

        if [ $with_cert_manager = true ]; then
                install_cert_manager
        fi

        if [ $with_tls = true ] && [ $with_auth = true ]; then
                install_nats_server_with_auth_and_tls
                install_nats_box_with_auth_and_tls

                if [ $with_stan = true ]; then
                        install_nats_streaming_with_auth_and_tls
                fi
        elif [ $with_auth = true ]; then
                install_nats_server_with_auth
                install_nats_box_with_auth

                if [ $with_stan = true ]; then
                        install_nats_streaming_with_auth
                fi
        else
                install_insecure_nats_server
                install_nats_box
        fi

        if [ $with_surveyor = true ]; then
                install_nats_surveyor_components
                if [ $with_tls = true ]; then
                        install_nats_surveyor_with_tls
                else
                        install_nats_surveyor
                fi
        fi
        kubectl wait --for=condition=Ready pod/nats-0   --timeout=60s
        kubectl wait --for=condition=Ready pod/nats-box --timeout=60s




        echo
        echo " +------------------------------------------+"
        echo " |                                          |"
        echo " | Done. Enjoy your new NATS cluster!       |"
        echo " |                                          |"
        echo " +------------------------------------------+"
        echo
        echo "=== Getting started"
        echo
        echo "You can now start receiving and sending messages using "
        echo "the nats-box instance deployed into your namespace:"
        echo
        echo "  kubectl exec -it pod/nats-box /bin/sh"
        echo
        if [ $with_auth = true ]; then
                echo "Using the test user account:"
                echo
                echo "  nats-sub -creds /var/run/nats/creds/test/test.creds -s nats 'test.>' &"
                echo "  nats-pub -creds /var/run/nats/creds/test/test.creds -s nats test.hi 'Hello World'"
                echo
                echo "Using the system account:"
                echo
                echo "  nats-sub -creds /var/run/nats/creds/sys/sys.creds -s nats://nats:4222 '>'"
                echo
        else
                echo "  nats-sub -s nats://nats:4222 '>' &"
                echo "  nats-pub -s nats://nats:4222 hello world"
                echo
        fi
        echo "The nats-box also includes nats-top which you can use to"
        echo "inspect the flow of messages from one of the members"
        echo "of the cluster."
        echo
        echo "  nats-top -s nats"
        echo

        if [ $with_stan = true ]; then
                echo "NATS Streaming with persistence is also available as part of your cluster."
                echo "It is installed under the STAN account so you can use the following credentials:"
                echo
                echo "  stan-pub -creds /var/run/nats/creds/stan/stan.creds -s nats test.hi 'Hello World'"
                echo "  stan-sub -creds /var/run/nats/creds/stan/stan.creds -s nats 'test.>'"
                echo
        fi

        if [ $with_surveyor = true ]; then
                echo "You can also connect to your monitoring dashboard:"
                echo
                echo "  kubectl port-forward deployments/nats-surveyor-grafana 3000:3000"
                echo
                echo "Then open the following in your browser:"
                echo
                echo "  http://127.0.0.1:3000/d/nats/nats-surveyor?refresh=5s&orgId=1"
                echo
        fi
}

main "$@"
