#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="kichain-2"
CHAIN_DENOM="uxki"
BINARY="kid"
CHEAT_SHEET="https://nodejumper.io/kichain/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

bash <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "Building binaries..." && sleep 1

cd || return
rm -rf kid
git clone https://github.com/KiFoundation/ki-tools.git
cd ki-tools || return
git checkout 3.0.0
make install
kid version # Mainnet-3.0.0

# replace nodejumper with your own moniker, if you'd like
kid config chain-id $CHAIN_ID
kid init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/KiFoundation/ki-networks/v0.1/Mainnet/kichain-2/genesis.json > $HOME/.kid/config/genesis.json
sha256sum $HOME/.kid/config/genesis.json # 0059e1cd40da1ece7f14133509c44980cf6b5c5407a877ce17edd3bc6266708c

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uxki"|g' $HOME/.kid/config/app.toml
seeds="24cbccfa8813accd0ebdb09e7cdb54cff2e8fcd9@51.89.166.197:26656"
peers="766ed622c79fa9cfd668db9741a1f72a5751e0cd@kichain.nodejumper.io:28656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.kid/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.kid/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.kid/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.kid/config/app.toml

printCyan "Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/kid.service > /dev/null << EOF
[Unit]
Description=Kichain Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which kid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

kid tendermint unsafe-reset-all --home $HOME/.kid --keep-addr-book

SNAP_RPC="https://kichain.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.kid/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable kid
sudo systemctl restart kid

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
