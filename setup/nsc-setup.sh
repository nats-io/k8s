#!/bin/sh

[ -z "$NKEYS_PATH" ] && {
    export NKEYS_PATH=$(pwd)/nsc/nkeys
}

[ -z "$NSC_HOME" ] && {
    export NSC_HOME=$(pwd)/nsc/accounts
}

if [ ! -f .nsc.env ]; then
  echo '
# NSC Environment Setup
export NKEYS_PATH=$(pwd)/nsc/nkeys
export NSC_HOME=$(pwd)/nsc/accounts
' > .nsc.env
fi

mkdir -p "$NKEYS_PATH"
mkdir -p "$NSC_HOME"
nsc add operator --name KO

# Create system account
nsc add account --name SYS
nsc add user    --name sys

# Create a couple of accounts (A & B) for testing purposes.
nsc add account --name A
nsc add user -a A \
             --name test \
             --allow-pubsub 'test.>' \
             --allow-pubsub 'test' \
             --allow-pubsub '_INBOX.>' \
             --allow-pubsub '_R_' \
             --allow-pubsub '_R_.>' \
             --allow-sub latency.on.test

# Add latency exporting for the test subject from account A.
nsc add export  -a A  --latency latency.on.test --sampling 100 --service -s test

# Add account B that imports services from A.
nsc add account --name B
nsc add user -a B \
             --name test \
             --allow-pubsub 'test.>' \
             --allow-pubsub 'test' \
             --allow-pubsub '_INBOX.>' \
             --allow-pubsub '_R_' \
             --allow-pubsub '_R_.>'

nsc add import --account B \
               --src-account $(nsc list accounts 2>&1 | awk '$2 == "A" {print $0}' | awk '{print $4}') \
               --remote-subject test --service --local-subject test

# Create account for STAN purposes.
nsc add account --name STAN
nsc add user    --name stan
