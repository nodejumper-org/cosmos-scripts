#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="reb_3333-1"
CHAIN_DENOM="arebus"
BINARY="rebusd"
CHEAT_SHEET="https://nodejumper.io/rebus-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf rebus.core
git clone https://github.com/rebuschain/rebus.core.git
cd rebus.core || return
git checkout testnet
make install
rebusd version # testnet.6f73acac323e89b6b1f7b38aa1ee884b39234e75

rebusd config chain-id $CHAIN_ID
rebusd init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/rebuschain/rebus.testnet/master/rebus_3333-1/genesis.json > $HOME/.rebusd/config/genesis.json
sha256sum $HOME/.rebusd/config/genesis.json # d382339b5187693ef2e57ff4f33c571ee9bb238ce9fcd68ca99c02116576c41b

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001arebus"|g' $HOME/.rebusd/config/app.toml
sed -i 's|^indexer *=.*|indexer = "null"|g' $HOME/.rebusd/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.rebusd/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.rebusd/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.rebusd/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.rebusd/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/rebusd.service > /dev/null << EOF
[Unit]
Description=Rebus Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which rebusd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

rebusd tendermint unsafe-reset-all --home $HOME/.rebusd --keep-addr-book

SNAP_RPC="https://rebus-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.rebusd/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable rebusd
sudo systemctl restart rebusd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
