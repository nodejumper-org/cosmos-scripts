#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="stride-1"
CHAIN_DENOM="ustrd"
BINARY="strided"
CHEAT_SHEET="https://nodejumper.io/stride/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

bash <(curl -s "https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/go_install.sh")
source .bash_profile

cd || return
rm -rf stride
git clone https://github.com/Stride-Labs/stride.git
cd stride || return
git checkout v4.0.2
go mod edit -replace github.com/cosmos/iavl=github.com/chillyvee/iavl@v0.19.4-blunt.3
go mod edit -replace github.com/cosmos/cosmos-sdk=github.com/chillyvee/cosmos-sdk@cv0.45.11snap.5
go mod tidy
make install
strided version # v4.0.2

strided config chain-id $CHAIN_ID
strided init $NODE_MONIKER --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/Stride-Labs/stride/main/genesis/genesis.json > $HOME/.stride/config/genesis.json
sha256sum $HOME/.stride/config/genesis.json # e31b8d1a9090f128b6f7db024836213d1af2b424bfb757e38f3b5c39be738aa4

curl -s https://snapshots2.nodejumper.io/stride/addrbook.json > $HOME/.stride/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ustrd"|g' $HOME/.stride/config/app.toml
seeds=""
peers="de048f413e6cceeba02139f581adb97d331651b8@stride.nodejumper.io:29656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.stride/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.stride/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.stride/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.stride/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/strided.service > /dev/null << EOF
[Unit]
Description=Stride Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which strided) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

strided tendermint unsafe-reset-all --home $HOME/.stride/ --keep-addr-book

SNAP_RPC="https://stride.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.stride/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable strided
sudo systemctl restart strided

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \printLine
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.rizon/config/config.tomlecho -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
