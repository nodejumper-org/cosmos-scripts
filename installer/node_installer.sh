#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/logo.sh)

while getopts c: flag; do
  case "${flag}" in
  c) configPath="$OPTARG" ;;
  *) echo "WARN: unknown parameter: ${OPTARG}" ;;
  esac
done

function checkDependencies {
  local jqInstalled=$(dpkg-query -W --showformat='${Status}\n' jq | grep "install ok installed")
  local ufwInstalled=$(dpkg-query -W --showformat='${Status}\n' ufw | grep "install ok installed")
  local curlInstalled=$(dpkg-query -W --showformat='${Status}\n' curl | grep "install ok installed")
  if [[ -z "$jqInstalled" || -z "$ufwInstalled" || -z "$curlInstalled" ]]; then
    echo "Installing dependencies"
    sudo apt update
    sudo apt install -y jq ufw curl
  fi
}

function configureNode {
  local config=$1

  echo "Setuping chain $(jq -r '.chainId' <<< "$config")"

  ### general
  local installationScriptUrl=$(jq -r '.installationScript' <<< "$config")
  local serviceName=$(jq -r '.serviceName' <<< "$config")
  local chainHomePath="$HOME/$(jq -r '.chainHomeDir' <<< "$config")"
  local stateSyncMode=$(jq -r '.stateSyncMode' <<<" $config")
  local prometheusIp=$(jq -r '.prometheusIp' <<<" $config")
  local tlsCertPath=$(jq -r '.tls.cert' <<< "$config")
  local tlsKeyPath=$(jq -r '.tls.key' <<< "$config")

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

  if [[ -n "$installationScriptUrl" && "$installationScriptUrl" != null ]]; then
    echo "Running script from url: $installationScriptUrl"
    . <(curl -s "$installationScriptUrl") "$moniker"
  fi

  ### client.toml
  if [ -f "$chainHomePath/config/client.toml" ]; then
    sed -i 's|chain-id = ""|chain-id = "'"$chainId"'"|g' "$chainHomePath/config/client.toml"
    sed -i 's|node = "tcp:\/\/localhost:26657"|node = "tcp:\/\/localhost:'"$portRpc"'"|g' "$chainHomePath/config/client.toml"
  fi

  ### app.toml
  sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "'"$minGasPrice"'"|g' "$chainHomePath/config/app.toml"
  sed -i 's|address = "0.0.0.0:9090"|address = "0.0.0.0:'"$portGrpc"'"|g' "$chainHomePath/config/app.toml"
  sed -i 's|address = "0.0.0.0:9091"|address = "0.0.0.0:'"$portGrpcWeb"'"|g' "$chainHomePath/config/app.toml"

  sed -i 's|pruning = "default"|pruning = "custom"|g' "$chainHomePath/config/app.toml"
  sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' "$chainHomePath/config/app.toml"
  sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' "$chainHomePath/config/app.toml"
  sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' "$chainHomePath/config/app.toml"

  if [ "$stateSyncMode" == true ]; then
    sed -i 's|pruning-keep-every = "0"|pruning-keep-every = "2000"|g' "$chainHomePath/config/app.toml"
    sed -i 's|^snapshot-interval *=.*|snapshot-interval = 2000|g' "$chainHomePath/config/app.toml"
  fi

  ### config.toml
  sed -i 's|laddr = "tcp:\/\/0.0.0.0:26656"|laddr = "tcp:\/\/0.0.0.0:'"$portP2P"'"|g' "$chainHomePath/config/config.toml"
  sed -i 's|pprof_laddr = "localhost:6060"|pprof_laddr = "localhost:'"$portPprof"'"|g' "$chainHomePath/config/config.toml"
  sed -i 's|^indexer *=.*|indexer = "'"$indexer"'"|g' "$chainHomePath/config/config.toml"
  sed -i 's|prometheus = false|prometheus = true|g' "$chainHomePath/config/config.toml"
  sed -i 's|prometheus_listen_addr = ":26660"|prometheus_listen_addr = ":'"$portPrometheus"'"|g' "$chainHomePath/config/config.toml"
  sed -i 's|proxy_app = "tcp:\/\/127.0.0.1:26658\"|proxy_app = "tcp:\/\/127.0.0.1:'"$portProxyApp"'"|g' "$chainHomePath/config/config.toml"

  if [[ -n "$tlsCertPath" && -n "$tlsKeyPath" && "$tlsCertPath" != null && "$tlsKeyPath" != null ]]; then
    sed -i 's|certificate-path = ""|certificate-path = "'"$tlsCertPath"'"|g' "$chainHomePath/config/app.toml"
    sed -i 's|key-path = ""|key-path = "'"$tlsCertPath"'"|g' "$chainHomePath/config/app.toml"
    sed -i 's|tls_key_file = ""|tls_key_file = "'"$tlsKeyPath"'"|g' "$chainHomePath/config/config.toml"
    sed -i 's|tls_key_file = ""|tls_key_file = "'"$tlsKeyPath"'"|g' "$chainHomePath/config/config.toml"
  fi

  if [ -n "$seeds" ]; then
    sed -i -e "s|^seeds *=.*|seeds = \"$seeds\"|" "$chainHomePath/config/config.toml"
  fi

  if [ -n "$peers" ]; then
    sed -i -e "s|^persistent_peers *=.*|persistent_peers = \"$peers\"|" "$chainHomePath/config/config.toml"
  fi

  if [ "$stateSyncMode" == true ]; then
    sed -i 's|laddr = "tcp:\/\/127.0.0.1:26657"|laddr = "tcp:\/\/0.0.0.0:'"$portRpc"'"|g' "$chainHomePath/config/config.toml"
    sed -i 's|cors_allowed_origins = \[\]|cors_allowed_origins = \["*"\]|g' "$chainHomePath/config/config.toml"
    sed -i 's|^max_num_inbound_peers *=.*|max_num_inbound_peers = 400|g' "$chainHomePath/config/config.toml"
    sed -i 's|^max_num_outbound_peers *=.*|max_num_outbound_peers = 100|g' "$chainHomePath/config/config.toml"
  else
    sed -i 's|laddr = "tcp:\/\/127.0.0.1:26657"|laddr = "tcp:\/\/127.0.0.1:'"$portRpc"'"|g' "$chainHomePath/config/config.toml"
  fi

  ### UFW
  echo "Setuping ufw rules"
  sudo ufw allow "$portP2P"

  if [[ -n "$prometheusIp" && -n "$portPrometheus" && "$prometheusIp" != null && "$portPrometheus" != null ]]; then
    sudo ufw allow from "$prometheusIp" to any port "$portPrometheus"
  fi

  if [ "$stateSyncMode" == true ]; then
    sudo ufw allow "$portRpc"
  fi

  echo "Restarting $serviceName service"
  sudo systemctl restart "$serviceName"
}

if [ -z "$configPath" ]; then
  echo "ERROR: config not provided"
  exit 1
fi

checkDependencies

echo "$(<"$configPath")" | jq -c -r '.[]' | while read -r config; do
  configureNode "$config"
done
