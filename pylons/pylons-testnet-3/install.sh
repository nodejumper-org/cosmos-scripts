#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="pylons-testnet-3"
CHAIN_DENOM="ubedrock"
BINARY="pylonsd"
CHEAT_SHEET="https://nodejumper.io/pylons-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf pylons
git clone https://github.com/Pylons-tech/pylons
cd pylons || return
git checkout v1.0.2
make install
pylonsd version # 1.0.2

pylonsd config keyring-backend test
pylonsd config chain-id $CHAIN_ID
pylonsd init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/Pylons-tech/pylons/main/networks/pylons-testnet-3/genesis.json > $HOME/.pylons/config/genesis.json
sha256sum $HOME/.pylons/config/genesis.json #87f2c34a80672b3c77a9477628759bd23920d276ab2401462bd9588e201e8a44

curl -s https://snapshots4-testnet.nodejumper.io/pylons-testnet/addrbook.json > $HOME/.pylons/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ubedrock"|g' $HOME/.pylons/config/app.toml
seeds="53dbaa70a1f7769f74e46ada1597f854fd616c2d@167.235.57.142:26657,7dfad917bf0cd651d75873802358e1d1d85a577d@94.130.111.155:26257,c09c7a1a50b4744011a006469c68bc2e763ef17a@88.99.3.158:10157,"
peers="910875c9577b0b51179ca8ab485196bab7c9b892@pylons-testnet.nodejumper.io:28656,d977d11f5741d8e9be84faa390af55de43659f0c@95.217.225.214:28656,c8467b5e9364b0b840363dd5eaa76ba6268ce48a@185.187.169.11:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.pylons/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "nothing"|g' $HOME/.pylons/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.pylons/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/pylonsd.service > /dev/null << EOF
[Unit]
Description=Pylons Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which pylonsd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

pylonsd tendermint unsafe-reset-all --home $HOME/.pylons --keep-addr-book

cd "$HOME/.pylons" || return
rm -rf data

SNAP_NAME=$(curl -s https://snapshots4-testnet.nodejumper.io/pylons-testnet/ | egrep -o ">pylons-testnet-3.*\.tar.lz4" | tr -d ">")
curl https://snapshots4-testnet.nodejumper.io/pylons-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf - -C $HOME/.pylons

sudo systemctl daemon-reload
sudo systemctl enable pylonsd
sudo systemctl restart pylonsd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"