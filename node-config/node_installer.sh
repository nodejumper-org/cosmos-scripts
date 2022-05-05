#!/bin/bash

while getopts c: flag; do
  case "${flag}" in
  c) CONFIG_PATH=$OPTARG ;;
  *) echo "WARN: unknown parameter: ${OPTARG}"
  esac
done

function checkClientToml {
  local chainHome=$1
  local clientTomlPath="$HOME/$chainHome/config/client.toml"
  echo "Checking if client toml exist. path: $clientTomlPath"
  if [ ! -f "$clientTomlPath" ]; then
    echo "File $clientTomlPath does not exist. Creating..."
    curl https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/node-config/client.toml > "$clientTomlPath"
  fi
}

function configureNode {
  local config=$1

  ### general
  local INSTALLATION_SCRIPT=$(jq -r '.installationScript' <<< "$config")
  local SERVICE_NAME=$(jq -r '.serviceName' <<< "$config")
  local CHAIN_HOME=$(jq -r '.chainHomeDir' <<< "$config")
  local STATE_SYNC_MODE=$(jq -r '.stateSyncMode' <<<" $config")

  ### client.toml
  local CHAIN_ID=$(jq -r '.chainId' <<< "$config")

  ### app.toml
  local MIN_GAS_PRICE=$(jq -r '.minGasPrice' <<< "$config")
  local PORT_GRPC=$(jq -r '.ports.grpc' <<< "$config")
  local PORT_GRPC_WEB=$(jq -r '.ports.grpcWeb' <<< "$config")

  ### config.toml
  local MONIKER=$(jq -r '.moniker' <<< "$config")
  local INDEXER=$(jq -r '.indexer' <<< "$config")

  local SEEDS=$(jq -r '.seeds' <<< "$config")
  local PEERS=$(jq -r '.peers' <<< "$config")

  local PORT_PROXY_APP=$(jq -r '.ports.proxyApp' <<< "$config")
  local PORT_RPC=$(jq -r '.ports.rpc' <<< "$config")
  local PORT_PPROF=$(jq -r '.ports.pprof' <<< "$config")
  local PORT_P2P=$(jq -r '.ports.p2p' <<< "$config")
  local PORT_PROMETHEUS=$(jq -r '.ports.prometheus' <<< "$config")

  local TLS_CERT=$(jq -r '.tls.cert' <<< "$config")
  local TLS_KEY=$(jq -r '.tls.key' <<< "$config")

  if [ -n "$INSTALLATION_SCRIPT" ]; then
    . <(curl -s "$INSTALLATION_SCRIPT") "$MONIKER"
  fi

  checkClientToml "$CHAIN_HOME"

  ### client.toml
  sed -i 's/chain-id = ""/chain-id = "'$CHAIN_ID'"/g' "$CHAIN_HOME/config/client.toml"
  sed -i 's|node = "tcp:\/\/localhost:26657"|node = "tcp:\/\/localhost:'$PORT_RPC'"|g' "$CHAIN_HOME/config/client.toml"

  ### app.toml
  sed -i 's/^minimum-gas-prices *=.*/minimum-gas-prices = "'$MIN_GAS_PRICE'"/g' "$CHAIN_HOME/config/app.toml"
  sed -i 's/address = "0.0.0.0:9090"/address = "0.0.0.0:'$PORT_GRPC'"/g' "$CHAIN_HOME/config/app.toml"
  sed -i 's/address = "0.0.0.0:9091"/address = "0.0.0.0:'$PORT_GRPC_WEB'"/g' "$CHAIN_HOME/config/app.toml"

  if [ "$STATE_SYNC_MODE" == "true" ]; then
    # set pruning to custom/100/2000/10
    sed -i 's/pruning = "default"/pruning = "custom"/g' "$CHAIN_HOME/config/app.toml"
    sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' "$CHAIN_HOME/config/app.toml"
    sed -i 's/pruning-keep-every = "0"/pruning-keep-recent = "2000"/g' "$CHAIN_HOME/config/app.toml"
    sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' "$CHAIN_HOME/config/app.toml"
    sed -i 's/snapshot-interval = 0/snapshot-interval = 2000/g' "$CHAIN_HOME/config/app.toml"
  else
    # set pruning to custom/100/0/10
    sed -i 's/pruning = "default"/pruning = "custom"/g' "$CHAIN_HOME/config/app.toml"
    sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' "$CHAIN_HOME/config/app.toml"
    sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' "$CHAIN_HOME/config/app.toml"
  fi

  ### config.toml
  sed -i 's|laddr = "tcp:\/\/0.0.0.0:26656"|laddr = "tcp:\/\/0.0.0.0:'$PORT_P2P'"|g' "$CHAIN_HOME/config/config.toml"
  sed -i 's|pprof_laddr = "localhost:6060"|pprof_laddr = "localhost:'$PORT_PPROF'"|g' "$CHAIN_HOME/config/config.toml"
  sed -i 's|indexer = "kv"|indexer = "'$INDEXER'"|g' "$CHAIN_HOME/config/config.toml"
  sed -i 's|prometheus = false|prometheus = true|g' "$CHAIN_HOME/config/config.toml"
  sed -i 's|prometheus_listen_addr = ":26660"|prometheus_listen_addr = ":'$PORT_PROMETHEUS'"|g' "$CHAIN_HOME/config/config.toml"
  sed -i 's|proxy_app = "tcp:\/\/127.0.0.1:26658\"|proxy_app = "tcp:\/\/127.0.0.1:'$PORT_PROXY_APP'"|g' "$CHAIN_HOME/config/config.toml"

  if [ -n "$TLS_CERT" ] && [ -n "$TLS_KEY" ] && [ "$TLS_CERT" != "null" ] && [ "$TLS_KEY" != "null" ]; then
    sed -i 's|tls_cert_file = ""|tls_cert_file = "'"$TLS_CERT"'"|g' "$CHAIN_HOME/config/config.toml"
    sed -i 's|tls_key_file = ""|tls_key_file = "'"$TLS_KEY"'"|g' "$CHAIN_HOME/config/config.toml"
  fi

  if [ -n "$SEEDS" ]; then
    sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/" "$CHAIN_HOME/config/config.toml"
  fi

  if [ -n "$PEERS" ]; then
    sed -i -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$CHAIN_HOME/config/config.toml"
  fi

  if [ "$STATE_SYNC_MODE" == "true" ]; then
    sed -i 's|laddr = "tcp:\/\/127.0.0.1:26657"|laddr = "tcp:\/\/0.0.0.0:'$PORT_RPC'"|g' "$CHAIN_HOME/config/config.toml"
    sed -i 's|cors_allowed_origins = \[\]|cors_allowed_origins = \["*"\]|g' "$CHAIN_HOME/config/config.toml"
    sed -i 's|max_num_inbound_peers = 40|max_num_inbound_peers = 400|g' "$CHAIN_HOME/config/config.toml"
    sed -i 's|max_num_outbound_peers = 10|max_num_outbound_peers = 100|g' "$CHAIN_HOME/config/config.toml"
  else
    sed -i 's|laddr = "tcp:\/\/127.0.0.1:26657"|laddr = "tcp:\/\/127.0.0.1:'$PORT_RPC'"|g' "$CHAIN_HOME/config/config.toml"
  fi

  ### UFW
  sudo ufw allow "$PORT_P2P"

  if [ -n "$PROMETHEUS_IP" ]; then
    sudo ufw allow from "$PROMETHEUS_IP" to any port "$PORT_PROMETHEUS"
  fi

  if [ "$STATE_SYNC_MODE" == "true" ]; then
    sudo ufw allow "$PORT_RPC"
  fi

  sudo systemctl restart "$SERVICE_NAME"
}

function exists {
  command -v "$1" >/dev/null 2>&1
}
if exists jq; then
  echo ''
else
  sudo apt update && sudo apt install -y jq < "/dev/null"
fi

if [ -z "$CONFIG_PATH" ]; then
  echo "ERROR: config not provided"
  exit 1
fi

JSON=$(<"$CONFIG_PATH")

echo "$JSON" | jq -c -r '.[]' | while read -r config; do
  configureNode "$config"
done
