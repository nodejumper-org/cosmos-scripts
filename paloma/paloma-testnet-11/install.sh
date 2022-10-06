#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="paloma-testnet-11"
CHAIN_DENOM="ugrain"
BINARY="palomad"
CHEAT_SHEET="https://nodejumper.io/paloma-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1
cd || return
curl -L https://github.com/CosmWasm/wasmvm/raw/main/internal/api/libwasmvm.x86_64.so > libwasmvm.x86_64.so
sudo mv -f libwasmvm.x86_64.so /usr/lib/libwasmvm.x86_64.so

# palomad binary
curl -L https://github.com/palomachain/paloma/releases/download/v0.10.4/paloma_Linux_x86_64.tar.gz > paloma.tar.gz
tar -xvzf paloma.tar.gz
rm -rf paloma.tar.gz
sudo mv -f palomad /usr/local/bin/palomad
palomad version # v0.10.2

palomad config chain-id $CHAIN_ID
palomad init $NODE_MONIKER --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-11/genesis.json > $HOME/.paloma/config/genesis.json
sha256sum $HOME/.paloma/config/genesis.json # 9e096c16bc8ae46d5839167ad8ed88a0e154e1dbc27c41dfbd460fec324d947c

curl -s https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-11/addrbook.json > $HOME/.paloma/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ugrain"|g' $HOME/.paloma/config/app.toml
seeds=""
peers="484e0d3cc02ba868d4ad68ec44caf89dd14d1845@paloma-testnet.nodejumper.io:33659,d363f84a8f40e655812436be4f0c8b3fc3543805@173.255.229.106:26659"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.paloma/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.paloma/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.paloma/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.paloma/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.paloma/config/app.toml

# pigeon binary and config
curl -L https://github.com/palomachain/pigeon/releases/download/v0.9.1/pigeon_Linux_x86_64.tar.gz > pigeon.tar.gz
tar -xvzf pigeon.tar.gz
rm -rf pigeon.tar.gz
sudo mv -f pigeon /usr/local/bin/pigeon
pigeon version # v0.9.1

mkdir -p $HOME/.pigeon

sudo tee $HOME/.pigeon/config.yaml > /dev/null << EOF
loop-timeout: 5s
health-check-port: 5757

paloma:
  chain-id: paloma-testnet-11
  call-timeout: 20s
  keyring-dir: ~/.paloma
  keyring-pass-env-name: PALOMA_KEYRING_PASS
  keyring-type: os
  signing-key: ${WALLET}
  base-rpc-url: http://localhost:26657
  gas-adjustment: 1.5
  gas-prices: 0.001ugrain
  account-prefix: paloma

evm:
  eth-main:
    chain-id: 1
    base-rpc-url: ${ETH_RPC_URL}
    keyring-pass-env-name: "ETH_PASSWORD"
    signing-key: ${ETH_SIGNING_KEY}
    keyring-dir: ~/.pigeon/keys/evm/eth-main
    gas-adjustment: 1.5
  bsc-main:
    chain-id: 56
    base-rpc-url: ${BSC_RPC_URL}
    keyring-pass-env-name: "BSC_PASSWORD"
    signing-key: ${BSC_SIGNING_KEY}
    keyring-dir: ~/.pigeon/keys/evm/bsc-main
    gas-adjustment: 1.5
EOF

sudo tee $HOME/.pigeon/env.sh > /dev/null << EOF
PALOMA_KEYRING_PASS=<your Paloma key password>
ETH_RPC_URL=<Your ETH mainnet RPC URL>
ETH_PASSWORD=<Your ETH Key Password>
ETH_SIGNING_KEY=<Your ETH SIGNING KEY>
BSC_RPC_URL=<Your BSC mainnet RPC URL>
BSC_PASSWORD=<Your BSC Key Password>
BSC_SIGNING_KEY=<Your BSC SIGNING KEY>
WALLET=<WALLET NAME>
EOF

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/palomad.service > /dev/null << EOF
[Unit]
Description=Paloma Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which palomad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="PIGEON_HEALTHCHECK_PORT=5757"
[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/pigeond.service > /dev/null << EOF
[Unit]
Description=Pigeon daemon
After=network-online.target
ConditionPathExists=$(which pigeon)

[Service]
Type=simple
Restart=always
RestartSec=5
User=$USER
WorkingDirectory=$HOME
EnvironmentFile=$HOME/.pigeon/env.sh
ExecStart=$(which pigeon) start
ExecReload=

[Install]
WantedBy=multi-user.target
EOF

palomad tendermint unsafe-reset-all --home $HOME/.paloma

cd "$HOME/.paloma" || return
rm -rf data

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/paloma-testnet/ | egrep -o ">paloma-testnet-11.*\.tar.lz4" | tr -d ">")
curl https://snapshots1-testnet.nodejumper.io/paloma-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf -

sudo systemctl daemon-reload
sudo systemctl enable palomad
sudo systemctl restart palomad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
