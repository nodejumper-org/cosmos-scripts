#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="banksy-testnet-2"
CHAIN_DENOM="upica"
BINARY_NAME="banksyd"
BINARY_VERSION_TAG="v2.3.3-testnet2fork"
CHEAT_SHEET="https://nodejumper.io/сomposable-testnet/cheat-sheet"

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
rm -rf composable-testnet
git clone https://github.com/notional-labs/composable-testnet.git
cd composable-testnet || return
git checkout v2.3.3-testnet2fork
make install

banksyd config chain-id $CHAIN_ID
banksyd config keyring-backend test
banksyd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -L https://raw.githubusercontent.com/notional-labs/composable-networks/main/testnet-2/genesis.json > $HOME/.banksy/config/genesis.json
curl -s https://snapshots1-testnet.nodejumper.io/composable-testnet/addrbook.json > $HOME/.banksy/config/addrbook.json

SEEDS="872c8a78a17a24d6f44e1126c46ef52069c7bb18@65.109.80.150:2630,5c2a752c9b1952dbed075c56c600c3a79b58c395@composable-testnet-seed.autostake.com:26976,20e1000e88125698264454a884812746c2eb4807@seeds.lavenderfive.com:22256,3f472746f46493309650e5a033076689996c8881@composable-testnet.rpc.kjnodes.com:15959,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:22256,945e8384ea51c5c6f7b9a90df8d8da120516d897@rpc.composable-t.indonode.net:47656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.banksy/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.banksy/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.banksy/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.banksy/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.banksy/config/app.toml
sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001upica"|g' $HOME/.banksy/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.banksy/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/banksyd.service > /dev/null << EOF
[Unit]
Description=Composable Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which banksyd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
WorkingDirectory=$HOME
[Install]
WantedBy=multi-user.target
EOF

banksyd tendermint unsafe-reset-all --home $HOME/.banksy --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/composable-testnet/info.json | jq -r .fileName)
curl "https://snapshots1-testnet.nodejumper.io/composable-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.banksy"

sudo systemctl daemon-reload
sudo systemctl enable banksyd
sudo systemctl start banksyd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
