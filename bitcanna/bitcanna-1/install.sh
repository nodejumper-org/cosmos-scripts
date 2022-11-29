#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="bitcanna-1"
CHAIN_DENOM="ubcna"
BINARY="bcnad"
CHEAT_SHEET="https://nodejumper.io/bitcanna/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf bcna
git clone https://github.com/BitCannaGlobal/bcna.git
cd bcna || return
git checkout v1.4.5
make install
bcnad version # 1.4.5

bcnad config chain-id $CHAIN_ID
bcnad init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/BitCannaGlobal/bcna/main/genesis.json > $HOME/.bcna/config/genesis.json
sha256sum $HOME/.bcna/config/genesis.json # cd7449a199e71c400778f894abb00874badda572ac5443b7ec48bb0aad052f29

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ubcna"|g' $HOME/.bcna/config/app.toml
seeds="d6aa4c9f3ccecb0cc52109a95962b4618d69dd3f@seed1.bitcanna.io:26656,23671067d0fd40aec523290585c7d8e91034a771@seed2.bitcanna.io:26656"
peers="45589e6147e36dda9e429668484d7614fb25b142@bitcanna.nodejumper.io:27656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.bcna/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.bcna/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.bcna/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.bcna/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/bcnad.service > /dev/null << EOF
[Unit]
Description=Bitcanna Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which bcnad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

bcnad tendermint unsafe-reset-all --home $HOME/.bcna --keep-addr-book

SNAP_RPC="https://bitcanna.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.bcna/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable bcnad
sudo systemctl restart bcnad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
