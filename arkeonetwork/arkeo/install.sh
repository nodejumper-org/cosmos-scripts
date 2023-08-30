#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="arkeo"
CHAIN_DENOM="uarkeo"
BINARY_NAME="arkeod"
CHEAT_SHEET="https://nodejumper.io/arkeo-testnet/cheat-sheet"
BINARY_VERSION_TAG="ab05b124336ace257baa2cac07f7d1bfeed9ac02"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag:  ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

wget https://snapshots-testnet.nodejumper.io/arkeonetwork-testnet/arkeod
chmod +x arkeod
mv arkeod $HOME/go/bin/

arkeod config keyring-backend test
arkeod config chain-id $CHAIN_ID
arkeod init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s http://seed.arkeo.network:26657/genesis | jq '.result.genesis' > $HOME/.arkeo/config/genesis.json
curl -s https://snapshots-testnet.nodejumper.io/arkeonetwork-testnet/addrbook.json > $HOME/.arkeo/config/addrbook.json

SEEDS="20e1000e88125698264454a884812746c2eb4807@seeds.lavenderfive.com:22856"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.arkeo/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.arkeo/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.arkeo/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "17"|g' $HOME/.arkeo/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.arkeo/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uarkeo"|g' $HOME/.arkeo/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.arkeo/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/arkeod.service > /dev/null << EOF
[Unit]
Description=Arkeo Network Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which arkeod) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

arkeod tendermint unsafe-reset-all --home $HOME/.arkeo --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots-testnet.nodejumper.io/arkeonetwork-testnet/info.json | jq -r .fileName)
curl "https://snapshots-testnet.nodejumper.io/arkeonetwork-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.arkeo"

sudo systemctl daemon-reload
sudo systemctl enable arkeod
sudo systemctl start arkeod

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
