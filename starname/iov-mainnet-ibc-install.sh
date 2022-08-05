#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="iov-mainnet-ibc"
CHAIN_DENOM="uiov"
BINARY="starnamed"
CHEAT_SHEET="https://nodejumper.io/starname/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
curl https://github.com/CosmWasm/wasmvm/raw/v0.13.0/api/libwasmvm.so > libwasmvm.so
sudo mv -f libwasmvm.so /lib/libwasmvm.so
rm -rf starnamed
git clone https://github.com/iov-one/starnamed.git
cd starnamed || return
git checkout v0.10.13
make install
starnamed version # v0.10.13

starnamed init $NODE_MONIKER --chain-id $CHAIN_ID

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

printCyan "5. Starting service and synchronization..." && sleep 1

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

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
