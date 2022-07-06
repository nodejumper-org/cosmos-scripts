#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)

if [ ! $NODEMONIKER ]; then
	read -p "Enter node moniker: " NODEMONIKER
fi

CHAIN_ID="killerqueen-1"
BINARY="quicksilverd"
CHEAT_SHEET="https://nodejumper.io/quicksilver-testnet/cheat-sheet"

echo "=================================================================================================="
echo -e "Node moniker: \e[1m\e[1;96m$NODEMONIKER\e[0m"
echo -e "Wallet name:  \e[1m\e[1;96mwallet\e[0m"
echo -e "Chain id:     \e[1m\e[1;96m$CHAIN_ID\e[0m"
echo "=================================================================================================="
sleep 2

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/install_common_packages.sh)

echo -e "\e[1m\e[1;96m4. Building binaries... \e[0m" && sleep 1

cd || return
rm -rf quicksilver
git clone https://github.com/ingenuity-build/quicksilver.git
cd quicksilver || return
git checkout v0.4.1
make install
quicksilverd version # v0.4.1

# replace nodejumper with your own moniker, if you'd like
quicksilverd config chain-id $CHAIN_ID
quicksilverd init $NODEMONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/ingenuity-build/testnets/main/killerqueen/genesis.json > $HOME/.quicksilverd/config/genesis.json
sha256sum $HOME/.quicksilverd/config/genesis.json # 3510dd3310e3a127507a513b3e9c8b24147f549bac013a5130df4b704f1bac75

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uqck"|g' $HOME/.quicksilverd/config/app.toml
seeds="dd3460ec11f78b4a7c4336f22a356fe00805ab64@seed.killerqueen-1.quicksilver.zone:26656,8603d0778bfe0a8d2f8eaa860dcdc5eb85b55982@seed02.killerqueen-1.quicksilver.zone:27676"
peers="420ddb75ac0c0eb27d46c41007f18a0bf5588fc0@rpc1-testnet.nodejumper.io:31656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.quicksilverd/config/config.toml
sed -i 's|^indexer *=.*|indexer = "null"|g' $HOME/.quicksilverd/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.quicksilverd/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.quicksilverd/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.quicksilverd/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.quicksilverd/config/app.toml

echo -e "\e[1m\e[1;96m5. Starting service and synchronization... \e[0m" && sleep 1

sudo tee /etc/systemd/system/quicksilverd.service > /dev/null << EOF
[Unit]
Description=Quicksilver Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which quicksilverd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

quicksilverd tendermint unsafe-reset-all --home $HOME/.quicksilverd --keep-addr-book

SNAP_RPC="http://rpc1-testnet.nodejumper.io:31657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.quicksilverd/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable quicksilverd
sudo systemctl restart quicksilverd

echo "=================================================================================================="
echo -e "Check logs:            \e[1m\e[1;96msudo journalctl -u $BINARY -f --no-hostname -o cat \e[0m"
echo -e "Check synchronization: \e[1m\e[1;96m$BINARY status 2>&1 | jq .SyncInfo.catching_up\e[0m"
echo -e "More commands:         \e[1m\e[1;96m$CHEAT_SHEET\e[0m"