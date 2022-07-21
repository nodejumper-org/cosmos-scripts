#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="uptick_7776-1"
CHAIN_DENOM="auptick"
BINARY="uptickd"
CHEAT_SHEET="https://nodejumper.io/uptick-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

bash <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf uptick
git clone https://github.com/UptickNetwork/uptick.git
cd uptick || return
git checkout v0.2.0
make install
uptickd version # v0.2.0

uptickd config chain-id $CHAIN_ID
uptickd init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/UptickNetwork/uptick-testnet/main/uptick_7776-1/genesis.json > $HOME/.uptickd/config/genesis.json
sha256sum $HOME/.uptickd/config/genesis.json # 1ca389503310668cad2a38662c7f84045699839cba48d13ce2af31956442c8b5

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001auptick"|g' $HOME/.uptickd/config/app.toml
seeds="7aad751eb956d65388f0cc37ab2ea179e2143e41@seed0.testnet.uptick.network:26656,7e6c759bcf03641c65659f1b9b2f05ec9de7391b@seed1.testnet.uptick.network:26656"
peers="ce7e61b565292d6606fc0fbf4b2bc364227a1ef0@uptick-testnet.nodejumper.io:30656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.uptickd/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.uptickd/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.uptickd/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.uptickd/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.uptickd/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/uptickd.service > /dev/null << EOF
[Unit]
Description=Uptick Network Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which uptickd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

uptickd tendermint unsafe-reset-all --home $HOME/.uptickd/ --keep-addr-book

SNAP_RPC="https://uptick-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.uptickd/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable uptickd
sudo systemctl restart uptickd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
