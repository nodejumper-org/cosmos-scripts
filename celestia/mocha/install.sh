#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="mocha"
CHAIN_DENOM="utia"
BINARY="celestia-appd"
CHEAT_SHEET="https://nodejumper.io/mocha-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd $HOME || return
rm -rf celestia-app
git clone https://github.com/celestiaorg/celestia-app.git
cd celestia-app || return
git checkout v0.11.0
make install
celestia-appd version # 0.11.0

celestia-appd config keyring-backend test
celestia-appd config chain-id $CHAIN_ID
celestia-appd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/celestiaorg/networks/master/mocha/genesis.json > $HOME/.celestia-app/config/genesis.json
sha256sum "$HOME/.celestia-app/config/genesis.json" # 05ef265e16f37d1f5aa2ec884be3782c38d71e59a6d57957235c5ca433aa8e05

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001utia"|g' $HOME/.celestia-app/config/app.toml

seeds=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/mocha/seeds.txt | tr -d '\n')
peers=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/mocha/peers.txt | tr -d '\n')
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.celestia-app/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.celestia-app/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.celestia-app/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.celestia-app/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/celestia-appd.service > /dev/null << EOF
[Unit]
Description=Celestia Validator Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which celestia-appd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

celestia-appd tendermint unsafe-reset-all --home $HOME/.celestia-app --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots3-testnet.nodejumper.io/celestia-testnet/ | egrep -o ">mocha.*\.tar.lz4" | tr -d ">")
curl https://snapshots3-testnet.nodejumper.io/celestia-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf - -C $HOME/.celestia-app

sudo systemctl daemon-reload
sudo systemctl enable celestia-appd
sudo systemctl restart celestia-appd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
