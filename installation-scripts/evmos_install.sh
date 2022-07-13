#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)

read -p "Enter node moniker: " NODEMONIKER

CHAIN_ID="evmos_9001-2"
BINARY="evmosd"
CHEAT_SHEET="https://nodejumper.io/evmos/cheat-sheet"

echo "=================================================================================================="
echo -e "Node moniker: \e[1m\e[1;96m$NODEMONIKER\e[0m"
echo -e "Wallet name:  \e[1m\e[1;96mwallet\e[0m"
echo -e "Chain id:     \e[1m\e[1;96m$CHAIN_ID\e[0m"
echo "=================================================================================================="
sleep 2

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/install_common_packages.sh)

echo -e "\e[1m\e[1;96m4. Building binaries... \e[0m" && sleep 1
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

echo -e "\e[1m\e[1;96m5. Starting service and synchronization... \e[0m" && sleep 1

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

echo "=================================================================================================="
echo -e "Check logs:            \e[1m\e[1;96msudo journalctl -u $BINARY -f --no-hostname -o cat \e[0m"
echo -e "Check synchronization: \e[1m\e[1;96m$BINARY status 2>&1 | jq .SyncInfo.catching_up\e[0m"
echo -e "More commands:         \e[1m\e[1;96m$CHEAT_SHEET\e[0m"