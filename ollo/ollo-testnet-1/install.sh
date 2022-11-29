#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="ollo-testnet-1"
CHAIN_DENOM="utollo"
BINARY="ollod"
CHEAT_SHEET="https://nodejumper.io/ollo-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf ollo
git clone https://github.com/OllO-Station/ollo.git
cd ollo || return
git checkout v0.0.1
make install
ollod version # latest

ollod config keyring-backend test
ollod config chain-id $CHAIN_ID
ollod init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/OllO-Station/networks/master/ollo-testnet-1/genesis.json > $HOME/.ollo/config/genesis.json
sha256sum $HOME/.ollo/config/genesis.json # 4852e73a212318cabaa6bf264e18e8aeeb42ee1e428addc0855341fad5dc7dae

curl -s https://snapshots2-testnet.nodejumper.io/ollo-testnet/addrbook.json > $HOME/.ollo/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001utollo"|g' $HOME/.ollo/config/app.toml
seeds=""
peers="6aa3e31cc85922be69779df9747d7a08326a44f2@ollo-testnet.nodejumper.io:28656,42beefd08b5f8580177d1506220db3a548090262@65.108.195.29:26116,69d2c02f413bea1376f5398646f0c2ce0f82d62e@141.94.73.93:26656,d4696aba0fbb58a31b2736819ddecf699d787edb@38.242.159.61:26656,ad204b3422acb2e9a364941e540c99203ec22c5c@212.23.222.93:26656,90ba3ab29147af2bc66a823d087ca49068d7974c@54.149.123.52:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.ollo/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.ollo/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.ollo/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.ollo/config/app.toml
sed -i 's|snapshot-interval = 0|snapshot-interval = 10000|g' $HOME/.ollo/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/ollod.service > /dev/null << EOF
[Unit]
Description=Ollo Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which ollod) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

ollod tendermint unsafe-reset-all --home $HOME/.ollo --keep-addr-book

SNAP_RPC="https://ollo-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.ollo/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable ollod
sudo systemctl restart ollod

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
