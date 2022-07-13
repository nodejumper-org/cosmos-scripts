#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)

read -p "Enter node moniker: " NODEMONIKER

CHAIN_ID="deweb-testnet-1"
BINARY="dewebd"
CHEAT_SHEET="https://nodejumper.io/dws-testnet/cheat-sheet"

echo "=================================================================================================="
echo -e "Node moniker: \e[1m\e[1;96m$NODEMONIKER\e[0m"
echo -e "Wallet name:  \e[1m\e[1;96mwallet\e[0m"
echo -e "Chain id:     \e[1m\e[1;96m$CHAIN_ID\e[0m"
echo "=================================================================================================="
sleep 2

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/install_common_packages.sh)

echo -e "\e[1m\e[1;96m4. Building binaries... \e[0m" && sleep 1

cd || return
rm -rf deweb
git clone https://github.com/deweb-services/deweb.git
cd deweb || return
git checkout v0.2
make install
dewebd version # 0.2

# replace nodejumper with your own moniker, if you'd like
dewebd config chain-id $CHAIN_ID
dewebd init $NODEMONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/deweb-services/deweb/main/genesis.json > $HOME/.deweb/config/genesis.json
sha256sum $HOME/.deweb/config/genesis.json # 13bf101d673990cb39e6af96e3c7e183da79bd89f6d249e9dc797ae81b3573c2

curl https://raw.githubusercontent.com/encipher88/deweb/main/addrbook.json > $HOME/.deweb/config/addrbook.json
sha256sum $HOME/.deweb/config/addrbook.json # ba7bea692350ca8918542a26cabd5616dbebe1ff109092cb1e98c864da58dabf

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001udws"|g' $HOME/.deweb/config/app.toml
seeds=""
peers="c5b45045b0555c439d94f4d81a5ec4d1a578f98c@dws-testnet.nodejumper.io:27656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.deweb/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.deweb/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.deweb/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.deweb/config/app.toml

echo -e "\e[1m\e[1;96m5. Starting service and synchronization... \e[0m" && sleep 1

sudo tee /etc/systemd/system/dewebd.service > /dev/null << EOF
[Unit]
Description=DWS Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which dewebd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

dewebd unsafe-reset-all

SNAP_RPC="https://dws-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.deweb/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable dewebd
sudo systemctl restart dewebd

echo "=================================================================================================="
echo -e "Check logs:            \e[1m\e[1;96msudo journalctl -u $BINARY -f --no-hostname -o cat \e[0m"
echo -e "Check synchronization: \e[1m\e[1;96m$BINARY status 2>&1 | jq .SyncInfo.catching_up\e[0m"
echo -e "More commands:         \e[1m\e[1;96m$CHEAT_SHEET\e[0m"