#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)

read -p "Enter node moniker: " NODEMONIKER

CHAIN_ID="titan-1"
BINARY="rizond"
CHEAT_SHEET="https://nodejumper.io/rizon/cheat-sheet"

echo "=================================================================================================="
echo -e "Node moniker: \e[1m\e[1;96m$NODEMONIKER\e[0m"
echo -e "Wallet name:  \e[1m\e[1;96mwallet\e[0m"
echo -e "Chain id:     \e[1m\e[1;96m$CHAIN_ID\e[0m"
echo "=================================================================================================="
sleep 2

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/install_common_packages.sh)

echo -e "\e[1m\e[1;96m4. Building binaries... \e[0m" && sleep 1

cd || return
rm -rf rizon
git clone https://github.com/rizon-world/rizon.git
cd rizon || return
git checkout v0.3.0
make install
rizond version # v0.3.0

# replace nodejumper with your own moniker, if you'd like
rizond config chain-id $CHAIN_ID
rizond init $NODEMONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/rizon-world/mainnet/master/genesis.json > $HOME/.rizon/config/genesis.json
sha256sum $HOME/.rizon/config/genesis.json # 6d5602e3746affea1096c729768bffd1f60633dfe88ae705f018d70fd3e90302  -

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uatolo"|g' $HOME/.rizon/config/app.toml
seeds="83c9cdc2db2b4eff4acc9cd7d664ad5ae6191080@seed-1.mainnet.rizon.world:26656,ae1476777536e2be26507c4fbcf86b67540adb64@seed-2.mainnet.rizon.world:26656,8abf316257a264dc8744dee6be4981cfbbcaf4e4@seed-3.mainnet.rizon.world:26656"
peers="0d51e8b9eb24f412dffc855c7bd854a8ecb3dff5@rizon.nodejumper.io:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.rizon/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.rizon/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.rizon/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.rizon/config/app.toml

echo -e "\e[1m\e[1;96m5. Starting service and synchronization... \e[0m" && sleep 1

sudo tee /etc/systemd/system/rizond.service > /dev/null << EOF
[Unit]
Description=Rizon Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which rizond) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

rizond unsafe-reset-all

SNAP_RPC="https://rizon.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.rizon/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable rizond
sudo systemctl restart rizond

echo "=================================================================================================="
echo -e "Check logs:            \e[1m\e[1;96msudo journalctl -u $BINARY -f --no-hostname -o cat \e[0m"
echo -e "Check synchronization: \e[1m\e[1;96m$BINARY status 2>&1 | jq .SyncInfo.catching_up\e[0m"
echo -e "More commands:         \e[1m\e[1;96m$CHEAT_SHEET\e[0m"