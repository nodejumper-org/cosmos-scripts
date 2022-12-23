#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="pylons-mainnet-1"
CHAIN_DENOM="ubedrock"
BINARY="pylonsd"
CHEAT_SHEET="https://nodejumper.io/pylons/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf pylons
git clone https://github.com/Pylons-tech/pylons
cd pylons || return
git checkout v1.1.1
make install
pylonsd version # 1.1.1

pylonsd config chain-id $CHAIN_ID
pylonsd init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/Pylons-tech/pylons/main/networks/pylons-mainnet-1/genesis.json > $HOME/.pylons/config/genesis.json
sha256sum $HOME/.pylons/config/genesis.json #c6e776a1de29a57ce4cb4d2cdbaa39ba5768e066fd4f097cca92ce7fcfa94a9c

curl -s https://snapshots3.nodejumper.io/pylons/addrbook.json > $HOME/.pylons/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ubedrock"|g' $HOME/.pylons/config/app.toml
seeds=""
peers="7b6b13bcbd30311a407e193d0c7b21ed3dc15cd1@pylons.nodejumper.io:30656,d977d11f5741d8e9be84faa390af55de43659f0c@95.217.225.214:28656,d71cb7a9cc84e3c06ce2dc90f340d21ae53390ff@54.37.129.164:46656,35c6b3b3f273e845da511751d98b54ca3fd56170@65.109.49.163:26651,98634f7f77334b0df7b9c4d16d41b31ace4ceaa8@81.16.237.142:11223,d6685eb44553000f5e7abfd560a7c70b534dcc25@65.108.199.222:21116,90e9144c74d83f966fbbda20c070a28d3d6e48a2@65.108.135.211:46656,5eb3daf435d1d8a14e0a42e9dfbeca6877b2d1ca@65.108.2.41:46656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.pylons/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.pylons/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.pylons/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.pylons/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/pylonsd.service > /dev/null << EOF
[Unit]
Description=Pylons Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which pylonsd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

pylonsd tendermint unsafe-reset-all --home $HOME/.pylons --keep-addr-book

SNAP_RPC="https://pylons.nodejumper.io:443"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.pylons/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable pylonsd
sudo systemctl restart pylonsd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"