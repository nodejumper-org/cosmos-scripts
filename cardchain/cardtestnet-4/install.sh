#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="cardtestnet-4"
CHAIN_DENOM="ubpf"
BINARY_NAME="cardchaind"
BINARY_VERSION_TAG="v0.9.0"
CHEAT_SHEET="https://nodejumper.io/cardchain-testnet/cheat-sheet"

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
rm -rf Cardchain
git clone https://github.com/DecentralCardGame/Cardchain
cd Cardchain || return
git checkout v0.9.0
cd cmd/Cardchaind || return
go mod download
go build
mkdir -p $HOME/go/bin
mv Cardchaind $HOME/go/bin/cardchaind

cardchaind config keyring-backend test
cardchaind config chain-id $CHAIN_ID
cardchaind init "$NODE_MONIKER" --chain-id $CHAIN_ID --home $HOME/.cardchain

curl -s http://45.136.28.158:3000/genesis.json > $HOME/.cardchain/config/genesis.json
curl -s https://snapshots-testnet.nodejumper.io/cardchain-testnet/addrbook.json > $HOME/.cardchain/config/addrbook.json

SEEDS=""
PEERS="1ed98c796bcdd0faf5a7ad8793d229e3c7d89543@lxgr.xyz:26656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.cardchain/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.cardchain/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.cardchain/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.cardchain/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.cardchain/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ubpf"|g' $HOME/.cardchain/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.cardchain/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/cardchaind.service > /dev/null << EOF
[Unit]
Description=Cardchain Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which cardchaind) start --home $HOME/.cardchain
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

cardchaind tendermint unsafe-reset-all --keep-addr-book --home $HOME/.cardchain

SNAP_NAME=$(curl -s https://snapshots-testnet.nodejumper.io/cardchain-testnet/info.json | jq -r .fileName)
curl "https://snapshots-testnet.nodejumper.io/cardchain-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.cardchain"
curl -s https://snapshots-testnet.nodejumper.io/cardchain-testnet/addrbook.json > "$HOME/.cardchain/config/addrbook.json"

sudo systemctl daemon-reload
sudo systemctl enable cardchaind
sudo systemctl start cardchaind

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u ${BINARY_NAME} -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
