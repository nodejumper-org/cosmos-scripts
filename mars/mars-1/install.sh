#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="mars-1"
CHAIN_DENOM="umars"
BINARY_NAME="marsd"
BINARY_VERSION_TAG="v1.0.0"
CHEAT_SHEET="https://nodejumper.io/mars/cheat-sheet"

printLine
echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

# install go 1.19.5
source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/go_install.sh) -v 1.19.5
source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf hub
git clone https://github.com/mars-protocol/hub
cd hub || return
git checkout v1.0.0
make install
marsd version # 1.0.0

marsd config keyring-backend test
marsd config chain-id $CHAIN_ID
marsd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/mars-protocol/networks/main/mars-1/genesis.json > $HOME/.mars/config/genesis.json

# TODO: add addrbook
# curl -s https://snapshots1-testnet.nodejumper.io/mars-testnet/addrbook.json > $HOME/.mars/config/addrbook.json

SEEDS="52de8a7e2ad3da459961f633e50f64bf597c7585@seed.marsprotocol.io:443,d2d2629c8c8a8815f85c58c90f80b94690468c4f@tenderseed.ccvalidators.com:26012,20e1000e88125698264454a884812746c2eb4807@seeds.lavenderfive.com:12856,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:18556"
PEERS="d2a2c21754be65ad4a4f1de1f6163f681a6e8af8@192.99.44.79:18556,2a66b2b518d908c91b734ac6bad07ae68e1553ba@141.94.171.61:26656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.mars/config/config.toml

PRUNING_INTERVAL=$(shuf -n1 -e 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97)
sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.mars/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.mars/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "'$PRUNING_INTERVAL'"|g' $HOME/.mars/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 2000|g' $HOME/.mars/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001umars"|g' $HOME/.mars/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.mars/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/marsd.service > /dev/null << EOF
[Unit]
Description=Mars Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which marsd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

# TODO: add sync scripts
#marsd tendermint unsafe-reset-all --home $HOME/.mars --keep-addr-book
#
#SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/mars-testnet/ | egrep -o ">ares-1.*\.tar.lz4" | tr -d ">")
#curl https://snapshots1-testnet.nodejumper.io/mars-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf - -C $HOME/.mars

sudo systemctl daemon-reload
sudo systemctl enable marsd
sudo systemctl start marsd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
