#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="stafihub-1"
CHAIN_DENOM="ufis"
BINARY="stafihubd"
CHEAT_SHEET="https://nodejumper.io/stafihub/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf stafihub
git clone https://github.com/stafihub/stafihub
cd stafihub || return
git checkout v0.2.3
make install
stafihubd version # 0.2.3

stafihubd config chain-id $CHAIN_ID
stafihubd init $NODE_MONIKER --chain-id $CHAIN_ID

curl "https://github.com/stafihub/network/raw/main/mainnets/stafihub-1(dragonberry)/genesis.json" > $HOME/.stafihub/config/genesis.json
sha256sum $HOME/.stafihub/config/genesis.json # 1d69460eb12c7b9a5ec3f11b3c494dd5471debd404d56f57adc428a5614acaec

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.001ufis"|g' $HOME/.stafihub/config/app.toml
seeds=""
peers="967d2fc0e58f5d7f7954c2059cef4de62e4c513f@stafihub.nodejumper.io:26656,bed296dfadd972ed07cab82c87a0ee5c182dea43@18.136.189.120:26656,045fe6e054a5abe35f5433bd333f0a1b18aa28cf@45.136.28.11:26656,d35d55635093fddb6de22295c8fe31de98efe6ef@5.161.120.176:26656,20c0b45c47426c51b3187aa5dca82d9900c2fb36@5.161.88.157:26656,70230067eb1e668d2566329e727c72c930e54de3@116.202.30.7:26656,03f3cb61c7c472044c37aeededde2ffe8884fa02@159.69.108.86:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.stafihub/config/config.toml
sed -i '/\[grpc\]/{:a;n;/enabled/s/false/true/;Ta};/\[api\]/{:a;n;/enable/s/false/true/;Ta;}' $HOME/.stafihub/config/app.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.stafihub/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.stafihub/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.stafihub/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/stafihubd.service > /dev/null << EOF
[Unit]
Description=Stafihub Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which stafihubd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

stafihubd tendermint unsafe-reset-all --home $HOME/.stafihub --keep-addr-book

SNAP_RPC="https://stafihub.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.stafihub/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable stafihubd
sudo systemctl restart stafihubd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
