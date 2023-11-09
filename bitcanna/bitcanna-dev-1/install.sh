#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="bitcanna-dev-1"
CHAIN_DENOM="ubcna"
BINARY_NAME="bcnad"
CHEAT_SHEET="https://nodejumper.io/bitcanna-testnet/cheat-sheet"
BINARY_VERSION_TAG="v3.0.3-rc3"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag:  ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf bcna
git clone https://github.com/BitCannaGlobal/bcna.git
cd bcna || return
git checkout v3.0.3-rc3
make install

bcnad config keyring-backend test
bcnad config chain-id $CHAIN_ID
bcnad init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/BitCannaGlobal/bcna/main/devnets/bitcanna-dev-1/genesis.json > $HOME/.bcna/config/genesis.json
curl -s https://snapshots-testnet.nodejumper.io/bitcanna-testnet/addrbook.json > $HOME/.bcna/config/addrbook.json

SEEDS="471341f9befeab582e845d5e9987b7a4889c202f@144.91.89.66:26656"
PEERS="80ee9ed689bfb329cf21b94aa12978e073226db4@212.227.151.143:26656,ba6c17d707cb0c4f81e0ef590f2e36152ff7dd1a@212.227.151.106:26656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.bcna/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.bcna/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.bcna/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "17"|g' $HOME/.bcna/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.bcna/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ubcna"|g' $HOME/.bcna/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.bcna/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/bcnad.service > /dev/null << EOF
[Unit]
Description=Bitcanna Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which bcnad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

bcnad tendermint unsafe-reset-all --home $HOME/.bcna --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots-testnet.nodejumper.io/bitcanna-testnet/info.json | jq -r .fileName)
curl "https://snapshots-testnet.nodejumper.io/bitcanna-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.bcna"

sudo systemctl daemon-reload
sudo systemctl enable bcnad
sudo systemctl start bcnad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
