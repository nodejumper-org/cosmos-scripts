#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="nois-1"
CHAIN_DENOM="unois"
BINARY_NAME="noisd"
BINARY_VERSION_TAG="v1.0.4"
CHEAT_SHEET="https://nodejumper.io/nois/cheat-sheet"

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
rm -rf noisd
git clone https://github.com/noislabs/noisd.git
cd noisd
git checkout v1.0.4
make install
noisd version # 1.0.4

noisd config chain-id $CHAIN_ID
noisd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/noislabs/networks/main/nois-1/genesis.json > $HOME/.noisd/config/genesis.json
curl -s https://snapshots.nodejumper.io/nois/addrbook.json > $HOME/.noisd/config/addrbook.json

SEEDS="b3e3bd436ee34c39055a4c9946a02feec232988c@seeds.cros-nest.com:56656,20e1000e88125698264454a884812746c2eb4807@seeds.lavenderfive.com:17356,c8db99691545545402a1c45fa897f3cb1a05aea6@nois-mainnet-seed.itrocket.net:36656"
PEERS="6d514b525db3a3a010848648a35c7118b844b330@65.108.44.149:46656,47e99c3e8bbd881952cf4a642c8c2c8d178f56de@51.79.77.103:36656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.noisd/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.noisd/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.noisd/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.noisd/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.noisd/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.001unois"|g' $HOME/.noisd/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.noisd/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/noisd.service > /dev/null << EOF
[Unit]
Description=Noisd Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which noisd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

noisd tendermint unsafe-reset-all --home $HOME/.noisd --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots.nodejumper.io/nois/info.json | jq -r .fileName)
curl "https://snapshots.nodejumper.io/nois/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.noisd"

sudo systemctl daemon-reload
sudo systemctl enable noisd
sudo systemctl start noisd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
