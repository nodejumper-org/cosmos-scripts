#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="iov-mainnet-ibc"
CHAIN_DENOM="uiov"
BINARY_NAME="starnamed"
BINARY_VERSION_TAG="v0.11.6"
CHEAT_SHEET="https://nodejumper.io/starname/cheat-sheet"

printLine
echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
curl https://github.com/CosmWasm/wasmvm/raw/v0.13.0/api/libwasmvm.so > libwasmvm.so
sudo mv -f libwasmvm.so /lib/libwasmvm.so
rm -rf starnamed
git clone https://github.com/iov-one/starnamed.git
cd starnamed || return
git checkout tags/v0.11.6
make build
mkdir -p $HOME/go/bin
sudo cp $HOME/starnamed/build/starnamed $HOME/go/bin
starnamed version # v0.11.6

starnamed init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://gist.githubusercontent.com/davepuchyr/6bea7bf369064d118195e9b15ea08a0f/raw/cf66fd02ea9336bd79cbc47dd47dcd30aad7831c/genesis.json > $HOME/.starnamed/config/genesis.json
curl -s https://snapshots.nodejumper.io/starname/addrbook.json > $HOME/.starnamed/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.starnamed/config/config.toml

PRUNING_INTERVAL=$(shuf -n1 -e 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97)
sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.starnamed/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.starnamed/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "'$PRUNING_INTERVAL'"|g' $HOME/.starnamed/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 2000|g' $HOME/.starnamed/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uiov"|g' $HOME/.starnamed/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.starnamed/config/config.toml

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

starnamed tendermint unsafe-reset-all --home $HOME/.starnamed --keep-addr-book

curl https://snapshots.nodejumper.io/starname/iov-mainnet-ibc_2023-02-07.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.starnamed

sudo systemctl daemon-reload
sudo systemctl enable starnamed
sudo systemctl start starnamed

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
