#!/bin/bash

while getopts c: flag; do
  case "${flag}" in
  c) configPath=$OPTARG ;;
  *) echo "WARN: unknown parameter: ${OPTARG}" ;;
  esac
done

function configureNode {
  local config=$1

  ### general
  local installationScriptUrl=$(jq -r '.installationScript' <<< "$config")
  local serviceName=$(jq -r '.serviceName' <<< "$config")
  local chainHomeDir="$HOME/$(jq -r '.chainHomeDir' <<< "$config")"
  local stateSyncMode=$(jq -r '.stateSyncMode' <<<" $config")
  local prometheusIp=$(jq -r '.prometheusIp' <<<" $config")

  ### client.toml
  local chainId=$(jq -r '.chainId' <<< "$config")

  ### app.toml
  local minGasPrice=$(jq -r '.minGasPrice' <<< "$config")
  local portGrpc=$(jq -r '.ports.grpc' <<< "$config")
  local portGrpcWeb=$(jq -r '.ports.grpcWeb' <<< "$config")

  ### config.toml
  local moniker=$(jq -r '.moniker' <<< "$config")
  local indexer=$(jq -r '.indexer' <<< "$config")

  local seeds=$(jq -r '.seeds' <<< "$config")
  local peers=$(jq -r '.peers' <<< "$config")

  local portProxyApp=$(jq -r '.ports.proxyApp' <<< "$config")
  local portRpc=$(jq -r '.ports.rpc' <<< "$config")
  local portPprof=$(jq -r '.ports.pprof' <<< "$config")
  local portP2P=$(jq -r '.ports.p2p' <<< "$config")
  local portPrometheus=$(jq -r '.ports.prometheus' <<< "$config")

  local tlsCertPath=$(jq -r '.tls.cert' <<< "$config")
  local tlsKeyPath=$(jq -r '.tls.key' <<< "$config")

  if [ -n "$installationScriptUrl" ]; then
    . <(curl -s "$installationScriptUrl") "$moniker"
  fi

  ### client.toml
  if [ -f "$chainHomeDir/config/client.toml" ]; then
    sed -i 's/chain-id = ""/chain-id = "'$chainId'"/g' "$chainHomeDir/config/client.toml"
    sed -i 's|node = "tcp:\/\/localhost:26657"|node = "tcp:\/\/localhost:'$portRpc'"|g' "$chainHomeDir/config/client.toml"
  fi

  ### app.toml
  sed -i 's/^minimum-gas-prices *=.*/minimum-gas-prices = "'$minGasPrice'"/g' "$chainHomeDir/config/app.toml"
  sed -i 's/address = "0.0.0.0:9090"/address = "0.0.0.0:'$portGrpc'"/g' "$chainHomeDir/config/app.toml"
  sed -i 's/address = "0.0.0.0:9091"/address = "0.0.0.0:'$portGrpcWeb'"/g' "$chainHomeDir/config/app.toml"

  if [ "$stateSyncMode" == "true" ]; then
    # set pruning to custom/100/2000/10
    sed -i 's/pruning = "default"/pruning = "custom"/g' "$chainHomeDir/config/app.toml"
    sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' "$chainHomeDir/config/app.toml"
    sed -i 's/pruning-keep-every = "0"/pruning-keep-recent = "2000"/g' "$chainHomeDir/config/app.toml"
    sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' "$chainHomeDir/config/app.toml"
    sed -i 's/snapshot-interval = 0/snapshot-interval = 2000/g' "$chainHomeDir/config/app.toml"
  else
    # set pruning to custom/100/0/10
    sed -i 's/pruning = "default"/pruning = "custom"/g' "$chainHomeDir/config/app.toml"
    sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' "$chainHomeDir/config/app.toml"
    sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' "$chainHomeDir/config/app.toml"
  fi

  ### config.toml
  sed -i 's|laddr = "tcp:\/\/0.0.0.0:26656"|laddr = "tcp:\/\/0.0.0.0:'$portP2P'"|g' "$chainHomeDir/config/config.toml"
  sed -i 's|pprof_laddr = "localhost:6060"|pprof_laddr = "localhost:'$portPprof'"|g' "$chainHomeDir/config/config.toml"
  sed -i 's|indexer = "kv"|indexer = "'$indexer'"|g' "$chainHomeDir/config/config.toml"
  sed -i 's|prometheus = false|prometheus = true|g' "$chainHomeDir/config/config.toml"
  sed -i 's|prometheus_listen_addr = ":26660"|prometheus_listen_addr = ":'$portPrometheus'"|g' "$chainHomeDir/config/config.toml"
  sed -i 's|proxy_app = "tcp:\/\/127.0.0.1:26658\"|proxy_app = "tcp:\/\/127.0.0.1:'$portProxyApp'"|g' "$chainHomeDir/config/config.toml"

  if [ -n "$tlsCertPath" ] && [ -n "$tlsKeyPath" ] && [ "$tlsCertPath" != "null" ] && [ "$tlsKeyPath" != "null" ]; then
    sed -i 's|tls_cert_file = ""|tls_cert_file = "'"$tlsCertPath"'"|g' "$chainHomeDir/config/config.toml"
    sed -i 's|tls_key_file = ""|tls_key_file = "'"$tlsKeyPath"'"|g' "$chainHomeDir/config/config.toml"
  fi

  if [ -n "$seeds" ]; then
    sed -i -e "s/^seeds *=.*/seeds = \"$seeds\"/" "$chainHomeDir/config/config.toml"
  fi

  if [ -n "$peers" ]; then
    sed -i -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" "$chainHomeDir/config/config.toml"
  fi

  if [ "$stateSyncMode" == "true" ]; then
    sed -i 's|laddr = "tcp:\/\/127.0.0.1:26657"|laddr = "tcp:\/\/0.0.0.0:'$portRpc'"|g' "$chainHomeDir/config/config.toml"
    sed -i 's|cors_allowed_origins = \[\]|cors_allowed_origins = \["*"\]|g' "$chainHomeDir/config/config.toml"
    sed -i 's|max_num_inbound_peers = 40|max_num_inbound_peers = 400|g' "$chainHomeDir/config/config.toml"
    sed -i 's|max_num_outbound_peers = 10|max_num_outbound_peers = 100|g' "$chainHomeDir/config/config.toml"
  else
    sed -i 's|laddr = "tcp:\/\/127.0.0.1:26657"|laddr = "tcp:\/\/127.0.0.1:'$portRpc'"|g' "$chainHomeDir/config/config.toml"
  fi

  ### UFW
  sudo ufw allow "$portP2P"

  if [ -n "$prometheusIp" ]; then
    sudo ufw allow from "$prometheusIp" to any port "$portPrometheus"
  fi

  if [ "$stateSyncMode" == "true" ]; then
    sudo ufw allow "$portRpc"
  fi

  sudo systemctl restart "$serviceName"
}

if [ -z "$configPath" ]; then
  echo "ERROR: config not provided"
  exit 1
fi

JSON=$(<"$configPath")

echo "$JSON" | jq -c -r '.[]' | while read -r config; do
  configureNode "$config"
done
