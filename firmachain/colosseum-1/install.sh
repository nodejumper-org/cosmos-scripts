#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="colosseum-1"
CHAIN_DENOM="ufct"
BINARY_NAME="firmachaind"
BINARY_VERSION_TAG="0.3.5-patch"
CHEAT_SHEET="https://nodejumper.io/firmachain/cheat-sheet"

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
rm -rf firmachain
git clone https://github.com/firmachain/firmachain
cd firmachain || return
git checkout 0.3.5-patch
make install
firmachaind version # 0.3.5-patch

firmachaind config keyring-backend file
firmachaind config chain-id $CHAIN_ID
firmachaind init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/firmachain/mainnet/main/colosseum-1/genesis.json > $HOME/.firmachain/config/genesis.json
# TODO:
#curl -s https://snapshots2.nodejumper.io/firmachain/addrbook.json > $HOME/.firmachain/config/addrbook.json

SEEDS="f89dcc15241e30323ae6f491011779d53f9a5487@mainnet-seed1.firmachain.dev:26656,04cce0da4cf5ceb5ffc04d158faddfc5dc419154@mainnet-seed2.firmachain.dev:26656,940977bdc070422b3a62e4985f2fe79b7ee737f7@mainnet-seed3.firmachain.dev:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.firmachain/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.firmachain/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.firmachain/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "17"|g' $HOME/.firmachain/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.firmachain/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.001ufct"|g' $HOME/.firmachain/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.firmachain/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/firmachaind.service > /dev/null << EOF
[Unit]
Description=Firmachain Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which firmachaind) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

# TODO:
#firmachaind tendermint unsafe-reset-all --home $HOME/.firmachain --keep-addr-book
#
#SNAP_NAME=$(curl -s https://snapshots2.nodejumper.io/firmachain/info.json | jq -r .fileName)
#curl "https://snapshots2.nodejumper.io/firmachain/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.firmachain"

sudo systemctl daemon-reload
sudo systemctl enable firmachaind
sudo systemctl start firmachaind

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
