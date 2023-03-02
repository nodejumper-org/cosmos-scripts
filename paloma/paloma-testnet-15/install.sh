#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="paloma-testnet-15"
CHAIN_DENOM="ugrain"
BINARY_NAME="palomad"
BINARY_VERSION_TAG="v0.11.6"
CHEAT_SHEET="https://nodejumper.io/paloma-testnet/cheat-sheet"

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

# palomad binary
curl -L https://github.com/palomachain/paloma/releases/download/v0.11.6/paloma_Linux_x86_64.tar.gz > paloma.tar.gz
tar -xvzf paloma.tar.gz
rm -rf paloma.tar.gz
sudo mv -f palomad /usr/local/bin/palomad
palomad version # v0.11.6

palomad config chain-id $CHAIN_ID
palomad init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-15/genesis.json > $HOME/.paloma/config/genesis.json
curl -s https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-15/addrbook.json > $HOME/.paloma/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.paloma/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.paloma/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.paloma/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.paloma/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 2000|g' $HOME/.paloma/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ugrain"|g' $HOME/.paloma/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.paloma/config/config.toml

# pigeon binary and config
curl -L https://github.com/palomachain/pigeon/releases/download/v0.11.5/pigeon_Linux_x86_64.tar.gz > pigeon.tar.gz
tar -xvzf pigeon.tar.gz
rm -rf pigeon.tar.gz
sudo mv -f pigeon /usr/local/bin/pigeon
pigeon version # v0.11.5

echo "export PIGEON_HEALTHCHECK_PORT=5757" >> $HOME/.bash_profile
source .bash_profile

mkdir -p $HOME/.pigeon

sudo tee $HOME/.pigeon/config.yaml > /dev/null << EOF
loop-timeout: 5s
health-check-port: 5757

paloma:
  chain-id: paloma-testnet-15
  call-timeout: 20s
  keyring-dir: ~/.paloma
  keyring-pass-env-name: PALOMA_KEYRING_PASSWORD
  keyring-type: os
  signing-key: \${WALLET}
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
  bnb-main:
    chain-id: 56
    base-rpc-url: \${BNB_RPC_URL}
    keyring-pass-env-name: "BNB_PASSWORD"
    signing-key: \${BNB_SIGNING_KEY}
    keyring-dir: ~/.pigeon/keys/evm/bnb-main
    gas-adjustment: 1.5
    tx-type: 0
  matic-main:
    chain-id: 56
    base-rpc-url: \${MATIC_RPC_URL}
    keyring-pass-env-name: "MATIC_PASSWORD"
    signing-key: \${MATIC_SIGNING_KEY}
    keyring-dir: ~/.pigeon/keys/evm/matic-main
    gas-adjustment: 1.5
    tx-type: 0
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

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/paloma-testnet/info.json | jq -r .fileName)
curl "https://snapshots1-testnet.nodejumper.io/paloma-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.paloma"

sudo systemctl daemon-reload
sudo systemctl enable palomad
sudo systemctl enable pigeond
sudo systemctl start pigeond
sudo systemctl start palomad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
