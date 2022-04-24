#!/bin/bash

while getopts c: flag
do
    case "${flag}" in
        c) CONFIG_PATH=$OPTARG;;
    esac
done

if [ -z "$CONFIG_PATH" ]; then
    echo "ERROR: config not provided"
    exit 1
fi

JSON=$(<$CONFIG_PATH)

configs=$(echo "$JSON" | jq -c -r '.[]')
for config in ${configs[@]}; do

    echo "config: $config"

    # TODO: SET DEFAULTS !
    
    MONIKER=$(jq '.moniker' <<< "$item")
    CHAIN_ID=$(jq '.chainId' <<< "$item")
    CHAIN_HOME=$(jq '.homePath' <<< "$item")
    MIN_GAS_PRICE=$(jq '.minGasPrice' <<< "$item")
    ENABLE_PRUNING=$(jq '.enableCustomPruning' <<< "$item")
    STATE_SYNC_MODE=$(jq '.stateSyncMode' <<< "$item")
    INDEXER=$(jq '.indexer' <<< "$item")

    SEEDS=$(jq '.seeds' <<< "$item")
    PEERS=$(jq '.peers' <<< "$item")

    PORT_API=$(jq '.ports.api' <<< "$item")
    PORT_ROSETTA=$(jq '.ports.rosetta' <<< "$item")
    PORT_GRPC=$(jq '.ports.grpc' <<< "$item")
    PORT_GRPC_WEB=$(jq '.ports.grpcWeb' <<< "$item")

    PORT_PROXY_APP=$(jq '.ports.proxyApp' <<< "$item")
    PORT_RPC=$(jq '.ports.rpc' <<< "$item")
    PORT_PPROF=$(jq '.ports.pprof' <<< "$item")
    PORT_P2P=$(jq '.ports.p2p' <<< "$item")
    PORT_PROMETHEUES=$(jq '.ports.prometheus' <<< "$item")

    TSL_CERT=$(jq '.tsl.cert' <<< "$item")
    TSL_KEY=$(jq '.tsl.key' <<< "$item")

    checkClientToml

    ##############
    ## client.toml
    ##############
    sed -i 's/chain-id = ""/chain-id = "'$CHAIN_ID'"/g' $CHAIN_HOME/config/client.toml
    sed -i 's|node = "tcp:\/\/localhost:26657"|node = "tcp:\/\/localhost:'$PORT_RPC'"|g' $CHAIN_HOME/config/client.toml

    ##############
    ## app.toml
    ##############
    sed -i 's/^minimum-gas-prices *=.*/minimum-gas-prices = "'$MIN_GAS_PRICE'"/g' $CHAIN_HOME/config/app.toml
    sed -i 's/address = "0.0.0.0:9090"/address = "0.0.0.0:'$PORT_GRPC'"/g' $CHAIN_HOME/config/app.toml
    sed -i 's/address = "0.0.0.0:9091"/address = "0.0.0.0:'$PORT_GRPC_WEB'"/g' $CHAIN_HOME/config/app.toml

    if [ "$STATE_SYNC_MODE" == "true" ]
    then
        # set pruning to custom/100/2000/10
        sed -i 's/pruning = "default"/pruning = "custom"/g' $CHAIN_HOME/config/app.toml
        sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "2000"/g' $CHAIN_HOME/config/app.toml
        sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' $CHAIN_HOME/config/app.toml
        sed -i 's/snapshot-interval = 0/snapshot-interval = 2000/g' $CHAIN_HOME/config/app.toml
    else
        # set pruning to custom/100/0/10
        sed -i 's/pruning = "default"/pruning = "custom"/g' $CHAIN_HOME/config/app.toml
        sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' $CHAIN_HOME/config/app.toml
        sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' $CHAIN_HOME/config/app.toml
    fi

    ##############
    ## config.toml
    ##############
    sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/" $CHAIN_HOME/config/config.toml
    sed -i -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $CHAIN_HOME/config/config.toml

    sed -i 's|laddr = "tcp:\/\/0.0.0.0:26656"|laddr = "tcp:\/\/0.0.0.0:'$PORT_P2P'"|g' $CHAIN_HOME/config/config.toml
    sed -i 's|pprof_laddr = "localhost:6060"|pprof_laddr = "localhost:6060:'$PORT_PPROF'"|g' $CHAIN_HOME/config/config.toml
    sed -i 's|indexer = "kv"|indexer = "'$INDEXER'"|g' $CHAIN_HOME/config/config.toml
    sed -i 's|prometheus = false|prometheus = true|g' $CHAIN_HOME/config/config.toml
    sed -i 's|prometheus_listen_addr = ":26660"|prometheus_listen_addr = ":'$PORT_PROMETHEUS'"|g' $CHAIN_HOME/config/config.toml
    sed -i 's|proxy_app = "tcp:\/\/127.0.0.1:26658\"|proxy_app = "tcp:\/\/127.0.0.1:'$PORT_PROXY_APP'"|g' $CHAIN_HOME/config/config.toml

    sed -i 's|tls_cert_file = ""|tls_cert_file = "'$TSL_CERT'"|g' $CHAIN_HOME/config/config.toml
    sed -i 's|tls_key_file = ""|tls_key_file = "'$TSL_KEY'"|g' $CHAIN_HOME/config/config.toml

    if [ "$STATE_SYNC_MODE" == "true" ]
    then
        sed -i 's|laddr = "tcp:\/\/127.0.0.1:26657"|laddr = "tcp:\/\/0.0.0.0:'$PORT_RPC'"|g' $CHAIN_HOME/config/config.toml
        sed -i 's|cors_allowed_origins = \[\]|cors_allowed_origins = \["*"\]|g' $CHAIN_HOME/config/config.toml
        sed -i 's|max_num_inbound_peers = 40|max_num_inbound_peers = 400|g' $CHAIN_HOME/config/config.toml
        sed -i 's|max_num_outbound_peers = 10|max_num_outbound_peers = 100|g' $CHAIN_HOME/config/config.toml
    else
        sed -i 's|laddr = "tcp:\/\/127.0.0.1:26657"|laddr = "tcp:\/\/127.0.0.1:'$PORT_RPC'"|g' $CHAIN_HOME/config/config.toml
    fi

    ##########
    ## UFW
    ##########
    sudo ufw allow $LADDR_P2P
    sudo ufw allow from $PROMETHEUS_IP to any port $PORT_PROMETHEUS
    
    if [ "$STATE_SYNC_MODE" == "true" ]
    then
        sudo ufw allow $LADDR_RPC
    fi
done

function checkClientToml {
    clientTomlPath="$CHAIN_HOME/config/client.toml"
    echo "checking if client toml exist. path: $clientTomlPath"
    if [ ! -f "$clientTomlPath" ]; then
        echo "$clientTomlPath does not exist. creating..."
        tee $clientTomlPath > /dev/null << EOF
# This is a TOML config file.
# For more information, see https://github.com/toml-lang/toml

###############################################################################
###                           Client Configuration                            ###
###############################################################################

# The network chain ID
chain-id = ""
# The keyring's backend, where the keys are stored (os|file|kwallet|pass|test|memory)
keyring-backend = "os"
# CLI output format (text|json)
output = "text"
# <host>:<port> to Tendermint RPC interface for this chain
node = "tcp://localhost:26657"
# Transaction broadcasting mode (sync|async|block)
broadcast-mode = "sync"
EOF
    fi
}
