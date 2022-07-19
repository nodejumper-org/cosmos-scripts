#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODEMONIKER

CHAIN_ID="evmos_9001-2"
CHAIN_DENOM="aevmos"
BINARY="evmosd"
CHEAT_SHEET="https://nodejumper.io/evmos/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODEMONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 2

bash <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "Building binaries..." && sleep 1
cd || return
rm -rf evmos
git clone https://github.com/tharsis/evmos
cd evmos || return
git checkout v6.0.1
make install
evmosd version # 6.0.1

# replace nodejumper with your own moniker, if you'd like
evmosd config chain-id $CHAIN_ID
evmosd init $NODEMONIKER --chain-id $CHAIN_ID

cd || return
curl -# -L -O https://github.com/tharsis/mainnet/raw/main/evmos_9001-2/genesis.json.zip
unzip genesis.json.zip
rm genesis.json.zip
mv -f genesis.json $HOME/.evmosd/config/genesis.json
sha256sum $HOME/.evmosd/config/genesis.json # 4aa13da5eb4b9705ae8a7c3e09d1c36b92d08247dad2a6ed1844d031fcfe296c

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001aevmos"|g' $HOME/.evmosd/config/app.toml
seeds=""
peers="876eadd24a1f4f9f88f4ea540cb1ff456a4e34ee@evmos.nodejumper.io:36656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.evmosd/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.evmosd/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.evmosd/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.evmosd/config/app.toml

printCyan "Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/evmosd.service > /dev/null << EOF
[Unit]
Description=Evmos Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which evmosd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

evmosd tendermint unsafe-reset-all --home $HOME/.evmosd --keep-addr-book

SNAP_RPC="https://evmos.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.evmosd/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable evmosd
sudo systemctl restart evmosd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
