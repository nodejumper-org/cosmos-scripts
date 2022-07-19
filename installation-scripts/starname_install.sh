#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)

read -p "Enter node moniker: " NODEMONIKER

CHAIN_ID="iov-mainnet-ibc"
CHAIN_DENOM="uiov"
BINARY="starnamed"
CHEAT_SHEET="https://nodejumper.io/starname/cheat-sheet"

echo "=================================================================================================="
echo -e "Node moniker: \e[1m\e[1;96m$NODEMONIKER\e[0m"
echo -e "Chain id:     \e[1m\e[1;96m$CHAIN_ID\e[0m"
echo -e "Chain demon:  \e[1m\e[1;96m$CHAIN_DENOM\e[0m"
echo "=================================================================================================="
sleep 2

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/install_common_packages.sh)

echo -e "\e[1m\e[1;96m4. Building binaries... \e[0m" && sleep 1

cd || return
curl https://github.com/CosmWasm/wasmvm/raw/v0.13.0/api/libwasmvm.so > libwasmvm.so
sudo mv -f libwasmvm.so /lib/libwasmvm.so
rm -rf starnamed
git clone https://github.com/iov-one/starnamed.git
cd starnamed || return
git checkout v0.10.13
make install
starnamed version # v0.10.13

# replace nodejumper with your own moniker, if you'd like
starnamed init $NODEMONIKER --chain-id $CHAIN_ID

curl https://gist.githubusercontent.com/davepuchyr/6bea7bf369064d118195e9b15ea08a0f/raw/cf66fd02ea9336bd79cbc47dd47dcd30aad7831c/genesis.json > $HOME/.starnamed/config/genesis.json
sha256sum $HOME/.starnamed/config/genesis.json # e20eb984b3a85eb3d2c76b94d1a30c4b3cfa47397d5da2ec60dca8bef6d40b17

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uiov"|g' $HOME/.starnamed/config/app.toml
seeds=""
peers="3180fdc5e477e675acd22e63477ce3a2db20edf9@starname.nodejumper.io:34656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.starnamed/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.starnamed/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.starnamed/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.starnamed/config/app.toml

echo -e "\e[1m\e[1;96m5. Starting service and synchronization... \e[0m" && sleep 1

sudo tee /etc/systemd/system/starnamed.service > /dev/null << EOF
[Unit]
Description=Starname Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which starnamed) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

starnamed unsafe-reset-all
rm -rf $HOME/.starnamed/data
cd .starnamed || return

SNAP_NAME=$(curl -s https://snapshots2.nodejumper.io/starname/ | egrep -o ">iov-mainnet-ibc.*\.tar.lz4" | tr -d ">")
echo "Downloading a snapshot..."
curl -# https://snapshots2.nodejumper.io/starname/"${SNAP_NAME}" | lz4 -dc - | tar -xf -

sudo systemctl daemon-reload
sudo systemctl enable starnamed
sudo systemctl restart starnamed

echo "=================================================================================================="
echo -e "Check logs:            \e[1m\e[1;96msudo journalctl -u $BINARY -f --no-hostname -o cat \e[0m"
echo -e "Check synchronization: \e[1m\e[1;96m$BINARY status 2>&1 | jq .SyncInfo.catching_up\e[0m"
echo -e "More commands:         \e[1m\e[1;96m$CHEAT_SHEET\e[0m"