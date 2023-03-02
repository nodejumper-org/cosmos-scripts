#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="reb_1111-1"
CHAIN_DENOM="arebus"
BINARY_NAME="rebusd"
BINARY_VERSION_TAG="v0.3.0"
CHEAT_SHEET="https://nodejumper.io/rebus/cheat-sheet"

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
rm -rf rebus.core
git clone https://github.com/rebuschain/rebus.core.git
cd rebus.core || return
git checkout v0.3.0
make install
rebusd version # 0.3.0

rebusd config chain-id $CHAIN_ID
rebusd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/rebuschain/rebus.mainnet/master/reb_1111-1/genesis.zip > ~/.rebusd/config/genesis.zip
rm -rf ~/.rebusd/config/genesis.json
unzip ~/.rebusd/config/genesis.zip -d ~/.rebusd/config

curl -s https://snapshots1.nodejumper.io/rebus/addrbook.json > $HOME/.rebusd/config/addrbook.json

SEEDS="e056318da91e77585f496333040e00e12f6941d1@51.83.97.166:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.rebusd/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.rebusd/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.rebusd/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.rebusd/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 2000|g' $HOME/.rebusd/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001arebus"|g' $HOME/.rebusd/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.rebusd/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/rebusd.service > /dev/null << EOF
[Unit]
Description=Rebus Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which rebusd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

rebusd tendermint unsafe-reset-all --home $HOME/.rebusd --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots1.nodejumper.io/rebus/info.json | jq -r .fileName)
curl "https://snapshots1.nodejumper.io/rebus/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.rebusd"

sudo systemctl daemon-reload
sudo systemctl enable rebusd
sudo systemctl start rebusd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
