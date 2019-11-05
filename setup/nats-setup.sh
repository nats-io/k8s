#!/bin/sh

export NKEYS_PATH=/nsc/nkeys
export NSC_HOME=/nsc/accounts
export NATS_CONFIG_HOME=/nsc/config
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
chown -R 1000:1000 /nsc
