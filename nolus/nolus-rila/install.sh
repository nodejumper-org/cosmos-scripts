#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="nolus-rila"
CHAIN_DENOM="unls"
BINARY="nolusd"
CHEAT_SHEET="https://nodejumper.io/nolus-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf nolus-core
git clone https://github.com/Nolus-Protocol/nolus-core.git
cd nolus-core || return
git checkout v0.1.39
make install
nolusd version # 0.1.39

nolusd config keyring-backend test
nolusd config chain-id $CHAIN_ID
nolusd init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/Nolus-Protocol/nolus-networks/main/testnet/nolus-rila/genesis.json > $HOME/.nolus/config/genesis.json
sha256sum $HOME/.nolus/config/genesis.json #d22ea6488afe58478c54afeb2d6b5a45622c797dfd75c91a8653eb1f094173c5

curl -s https://snapshots4-testnet.nodejumper.io/nolus-testnet/addrbook.json > $HOME/.nolus/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001unls"|g' $HOME/.nolus/config/app.toml
seeds=""
peers=""
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.nolus/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.nolus/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.nolus/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.nolus/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/nolusd.service > /dev/null << EOF
[Unit]
Description=Nolus Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which nolusd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

nolusd tendermint unsafe-reset-all --home $HOME/.nolus --keep-addr-book

SNAP_RPC="https://nolus-testnet.nodejumper.io:443"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.nolus/config/config.toml

curl https://snapshots4-testnet.nodejumper.io/nolus-testnet/wasm.lz4 | lz4 -dc - | tar -xf - -C $HOME/.nolus

sudo systemctl daemon-reload
sudo systemctl enable nolusd
sudo systemctl restart nolusd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
