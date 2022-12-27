#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="defund-private-3"
CHAIN_DENOM="ufetf"
BINARY_NAME="defundd"
BINARY_VERSION_TAG="v0.2.1"
CHEAT_SHEET="https://nodejumper.io/defund-testnet/cheat-sheet"

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
rm -rf defund
git clone https://github.com/defund-labs/defund.git
cd defund || return
git checkout v0.2.1
make install
defundd version # 0.2.1

defundd config keyring-backend test
defundd config chain-id $CHAIN_ID
defundd init "$NODE_MONIKER" --chain-id $CHAIN_ID

cd || return
curl -Ls https://github.com/defund-labs/testnet/raw/main/defund-private-3/defund-private-3-gensis.tar.gz > defund-private-3-gensis.tar.gz
tar -xvzf defund-private-3-gensis.tar.gz
rm -rf defund-private-3-gensis.tar.gz
sudo mv -f genesis.json $HOME/.defund/config/genesis.json

curl -s https://snapshots3-testnet.nodejumper.io/defund-testnet/addrbook.json > $HOME/.defund/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.defund/config/config.toml

PRUNING_INTERVAL=$(shuf -n1 -e 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97)
sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.defund/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.defund/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "'$PRUNING_INTERVAL'"|g' $HOME/.defund/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 2000|g' $HOME/.defund/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ufetf"|g' $HOME/.defund/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.defund/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/defundd.service > /dev/null << EOF
[Unit]
Description=Defund Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which defundd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

defundd tendermint unsafe-reset-all --home $HOME/.defund --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots3-testnet.nodejumper.io/defund-testnet/ | egrep -o ">defund-private-3.*\.tar.lz4" | tr -d ">")
curl https://snapshots3-testnet.nodejumper.io/defund-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf - -C $HOME/.defund

sudo systemctl daemon-reload
sudo systemctl enable defundd
sudo systemctl start defundd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
