#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)

read -p "Enter node moniker: " NODEMONIKER

CHAIN_ID="harpoon-4"
BINARY="kujirad"
CHEAT_SHEET="https://nodejumper.io/kujira-testnet/cheat-sheet"

echo "=================================================================================================="
echo -e "Node moniker: \e[1m\e[1;96m$NODEMONIKER\e[0m"
echo -e "Wallet name:  \e[1m\e[1;96mwallet\e[0m"
echo -e "Chain id:     \e[1m\e[1;96m$CHAIN_ID\e[0m"
echo "=================================================================================================="
sleep 2

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/install_common_packages.sh)

echo -e "\e[1m\e[1;96m4. Building binaries... \e[0m" && sleep 1

cd || return
rm -rf kujira-core
git clone https://github.com/Team-Kujira/core kujira-core
cd kujira-core || return
git checkout v0.4.0
make install
kujirad version # 0.4.0

# replace nodejumper with your own moniker, if you'd like
kujirad config chain-id $CHAIN_ID
kujirad init $NODEMONIKER --chain-id $CHAIN_ID -o

curl https://raw.githubusercontent.com/Team-Kujira/networks/master/testnet/harpoon-4.json > $HOME/.kujira/config/genesis.json
sha256sum $HOME/.kujira/config/genesis.json # c5e258a28511b7f3f4e58993edd3b98ec7c716fe20b5c5813eec9babb696bd02

curl https://raw.githubusercontent.com/Team-Kujira/networks/master/testnet/addrbook.json > $HOME/.kujira/config/addrbook.json
sha256sum $HOME/.kujira/config/addrbook.json # 620fe1d5caf6544d61ea887c0c84664a1d3a0ea150a34dee21800c704262ba03

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ukuji"|g' $HOME/.kujira/config/app.toml
seeds=""
peers="eaa7e55efc03f23c5f461f71c06d444693d5352b@rpc1-testnet.nodejumper.io:29656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.kujira/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.kujira/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.kujira/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.kujira/config/app.toml

echo -e "\e[1m\e[1;96m5. Starting service and synchronization... \e[0m" && sleep 1

sudo tee /etc/systemd/system/kujirad.service > /dev/null << EOF
[Unit]
Description=Kujira Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which kujirad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

kujirad tendermint unsafe-reset-all --home $HOME/.kujira --keep-addr-book

SNAP_RPC="http://rpc1-testnet.nodejumper.io:29657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.kujira/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable kujirad
sudo systemctl restart kujirad

echo "=================================================================================================="
echo -e "Check logs:            \e[1m\e[1;96msudo journalctl -u $BINARY -f --no-hostname -o cat \e[0m"
echo -e "Check synchronization: \e[1m\e[1;96m$BINARY status 2>&1 | jq .SyncInfo.catching_up\e[0m"
echo -e "More commands:         \e[1m\e[1;96m$CHEAT_SHEET\e[0m"