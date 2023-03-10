#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="ojo-devnet"
CHAIN_DENOM="uojo"
BINARY_NAME="ojod"
BINARY_VERSION_TAG="v0.1.2"
CHEAT_SHEET="https://nodejumper.io/ojo-testnet/cheat-sheet"

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
rm -rf ojo
git clone https://github.com/ojo-network/ojo
cd ojo || return
git checkout v0.1.2
make install
ojod version # HEAD-ad5a2377134aa13d7d76575b95613cf8ed12d1e4

ojod config keyring-backend test
ojod config chain-id $CHAIN_ID
ojod init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -Ls https://rpc.devnet-n0.ojo-devnet.node.ojo.network/genesis > $HOME/.ojo/config/genesis.json
curl -s https://snapshots2-testnet.nodejumper.io/ojo-testnet/addrbook.json > $HOME/.ojo/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.ojo/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.ojo/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.ojo/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.ojo/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.ojo/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uojod"|g' $HOME/.ojo/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.ojo/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/ojod.service > /dev/null << EOF
[Unit]
Description=Ojo Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which ojod) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000

[Install]
WantedBy=multi-user.target
EOF

ojod tendermint unsafe-reset-all --home $HOME/.ojo --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots2-testnet.nodejumper.io/ojo-testnet/info.json | jq -r .fileName)
curl "https://snapshots2-testnet.nodejumper.io/ojo-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C $HOME/.ojo

sudo systemctl daemon-reload
sudo systemctl enable ojod
sudo systemctl start ojod

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
