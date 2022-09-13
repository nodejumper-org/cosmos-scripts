#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="reb_1111-1"
CHAIN_DENOM="arebus"
BINARY="rebusd"
CHEAT_SHEET="https://nodejumper.io/rebus/cheat-sheet"

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
git checkout master
make install
rebusd version # master.725ab954b6582cda056ef84deb1c6a5f816cd37b

rebusd config chain-id $CHAIN_ID
rebusd init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/rebuschain/rebus.mainnet/master/reb_1111-1/genesis.zip > ~/.rebusd/config/genesis.zip
rm -rf ~/.rebusd/config/genesis.json
unzip ~/.rebusd/config/genesis.zip -d ~/.rebusd/config
sha256sum $HOME/.rebusd/config/genesis.json # 10cc853d7ccc8ebc67155ee4ffc1bb32caac3f05873df79e866524898b3f20eb

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001arebus"|g' $HOME/.rebusd/config/app.toml
seeds="e056318da91e77585f496333040e00e12f6941d1@51.83.97.166:26656"
peers=""
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.rebusd/config/config.toml

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

SNAP_RPC="https://rebus.nodejumper.io:443"
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
