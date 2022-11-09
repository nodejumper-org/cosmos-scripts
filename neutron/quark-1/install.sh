#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="quark-1"
CHAIN_DENOM="untrn"
BINARY="neutrond"
CHEAT_SHEET="https://nodejumper.io/neutron-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf neutron
git clone https://github.com/neutron-org/neutron.git
cd neutron || return
git checkout v0.0.1
make install
neutrond version # 0.0.1

neutrond config keyring-backend test
neutrond config chain-id $CHAIN_ID
neutrond init $NODE_MONIKER --chain-id $CHAIN_ID

curl -s https://rpc.testnet-1.neutron.fi/genesis | jq -r .result.genesis > $HOME/.neutrond/config/genesis.json
sha256sum $HOME/.neutrond/config/genesis.json # b58b61beb34f0d9e45ec2f1449f6600acef428b401976dc90edb9d586a412ed2

curl -s https://snapshots3-testnet.nodejumper.io/neutron-testnet/addrbook.json > $HOME/.neutrond/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001untrn"|g' $HOME/.neutrond/config/app.toml
seeds=""
peers="6369a00a9b60ec53a1e76435f88cba798c9a9b9c@neutron-testnet.nodejumper.io:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.neutrond/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.neutrond/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.neutrond/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.neutrond/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/neutrondd.service > /dev/null << EOF
[Unit]
Description=Neutron Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which neutrond) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

neutrond tendermint unsafe-reset-all --home $HOME/.neutrond --keep-addr-book

SNAP_RPC="https://neutron-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.neutrond/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable neutrondd
sudo systemctl restart neutrondd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
