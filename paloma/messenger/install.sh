#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="messenger"
CHAIN_DENOM="ugrain"
BINARY_NAME="palomad"
BINARY_VERSION_TAG="v1.0.0"
CHEAT_SHEET="https://nodejumper.io/paloma/cheat-sheet"

printLine
echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
curl -L https://github.com/CosmWasm/wasmvm/raw/main/internal/api/libwasmvm.x86_64.so > libwasmvm.x86_64.so
sudo mv -f libwasmvm.x86_64.so /usr/lib/libwasmvm.x86_64.so

cd || return
rm -rf paloma
git clone https://github.com/palomachain/paloma.git
cd paloma || return
git checkout v1.0.0
make install
sudo mv -f $HOME/go/bin/palomad /usr/local/bin/palomad
palomad version # v1.0.0

curl -L https://github.com/palomachain/pigeon/releases/download/v1.0.0/pigeon_Linux_x86_64.tar.gz > pigeon.tar.gz
tar -xvzf pigeon.tar.gz
rm -rf pigeon.tar.gz
sudo mv -f pigeon /usr/local/bin/pigeon
pigeon version # v1.0.0

palomad init "$NODE_MONIKER" --chain-id $CHAIN_ID
palomad config chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/palomachain/mainnet/master/messenger/genesis.json > $HOME/.paloma/config/genesis.json

SEEDS=""
PEERS="ab6875bd52d6493f39612eb5dff57ced1e3a5ad6@95.217.229.18:10656,9581fadb9a32f2af89d575bb0f2661b9bb216d41@46.4.23.108:26656,4e35ce47a8c2654a0cd371a2d1485e157b6ce311@93.190.141.218:26656,874ccf9df2e4c678a18a1fb45a1d3bb703f87fa0@65.109.172.249:26656,6ee0ed8ddb1eaaf095686962d71fddb1383b5199@65.21.138.123:26656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.paloma/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.paloma/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.paloma/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.paloma/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.paloma/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ugrain"|g' $HOME/.paloma/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.paloma/config/config.toml

echo "export PIGEON_HEALTHCHECK_PORT=5757" >> $HOME/.bash_profile
source .bash_profile

mkdir -p $HOME/.pigeon

sudo tee $HOME/.pigeon/config.yaml > /dev/null << EOF
loop-timeout: 5s
health-check-port: 5757

paloma:
  chain-id: messenger
  call-timeout: 20s
  keyring-dir: ~/.paloma
  keyring-pass-env-name: PALOMA_PASSWORD
  keyring-type: os
  signing-key: wallet
  base-rpc-url: http://localhost:26657
  gas-adjustment: 1.5
  gas-prices: 0.001ugrain
  account-prefix: paloma

evm:
  eth-main:
    chain-id: 1
    base-rpc-url: \${ETH_RPC_URL}
    keyring-pass-env-name: "ETH_PASSWORD"
    signing-key: \${ETH_SIGNING_KEY}
    keyring-dir: ~/.pigeon/keys/evm/eth-main
    gas-adjustment: 1.9
    tx-type: 2
EOF

palomad keys add wallet --recover
pigeon evm keys generate-new $HOME/.pigeon/keys/evm/eth-main

PALOMA_PASSWORD=<YOUR_PALOMA_PASSWORD>
ETH_PASSWORD=<YOUR_ETH_PASSWORD>
ETH_SIGNING_KEY=0x$(cat $HOME/.pigeon/keys/evm/eth-main/*  | jq -r .address | head -n 1)

sudo tee $HOME/.pigeon/env.sh > /dev/null << EOF
PALOMA_PASSWORD=$PALOMA_PASSWORD
ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/9bYS5h99MVmaa7f0fYztaHwN31k2EBvZ
ETH_PASSWORD=$ETH_PASSWORD
ETH_SIGNING_KEY=$ETH_SIGNING_KEY
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

palomad tendermint unsafe-reset-all --home $HOME/.paloma --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots1.nodejumper.io/paloma/info.json | jq -r .fileName)
curl "https://snapshots1.nodejumper.io/paloma/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.paloma"

sudo systemctl daemon-reload
sudo systemctl enable palomad
sudo systemctl enable pigeond
sudo systemctl start pigeond
sudo systemctl start palomad

sudo journalctl -u pigeond -f --no-hostname -o cat
printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
