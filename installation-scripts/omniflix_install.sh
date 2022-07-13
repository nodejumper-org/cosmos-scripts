#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)

read -p "Enter node moniker: " NODEMONIKER

CHAIN_ID="omniflixhub-1"
BINARY="omniflixhubd"
CHEAT_SHEET="https://nodejumper.io/omniflix/cheat-sheet"

echo "=================================================================================================="
echo -e "Node moniker: \e[1m\e[1;96m$NODEMONIKER\e[0m"
echo -e "Wallet name:  \e[1m\e[1;96mwallet\e[0m"
echo -e "Chain id:     \e[1m\e[1;96m$CHAIN_ID\e[0m"
echo "=================================================================================================="
sleep 2

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/install_common_packages.sh)

echo -e "\e[1m\e[1;96m4. Building binaries... \e[0m" && sleep 1

cd || return
rm -rf omniflixhub
git clone https://github.com/Omniflix/omniflixhub.git
cd omniflixhub || return
git checkout v0.4.0
make install
omniflixhubd version # 0.4.0

# replace nodejumper with your own moniker, if you'd like
omniflixhubd config chain-id $CHAIN_ID
omniflixhubd init $NODEMONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/OmniFlix/mainnet/main/omniflixhub-1/genesis.json > $HOME/.omniflixhub/config/genesis.json
sha256sum $HOME/.omniflixhub/config/genesis.json # 4d6b5449d4db78807b634d90d9a92468747c7a6abfb5aa94a3b1198b2a367417

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uflix"|g' $HOME/.omniflixhub/config/app.toml
seeds="9d75a06ebd3732a041df459849c21b87b2c55cde@35.187.240.195:26656,19feae28207474eb9f168fff9720fd4d418df1ed@35.240.196.102:26656"
peers="b7ac7a52dbb4041133e31e0552f4e01e926d3bb4@omniflix.nodejumper.io:33656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.omniflixhub/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.omniflixhub/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.omniflixhub/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.omniflixhub/config/app.toml

echo -e "\e[1m\e[1;96m5. Starting service and synchronization... \e[0m" && sleep 1

sudo tee /etc/systemd/system/omniflixhubd.service > /dev/null << EOF
[Unit]
Description=Omniflix Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which omniflixhubd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

omniflixhubd unsafe-reset-all

SNAP_RPC="https://omniflix.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.omniflixhub/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable omniflixhubd
sudo systemctl restart omniflixhubd

echo "=================================================================================================="
echo -e "Check logs:            \e[1m\e[1;96msudo journalctl -u $BINARY -f --no-hostname -o cat \e[0m"
echo -e "Check synchronization: \e[1m\e[1;96m$BINARY status 2>&1 | jq .SyncInfo.catching_up\e[0m"
echo -e "More commands:         \e[1m\e[1;96m$CHEAT_SHEET\e[0m"