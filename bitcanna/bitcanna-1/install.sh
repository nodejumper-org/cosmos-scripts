#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p -r "Enter node moniker: " NODE_MONIKER

CHAIN_ID="bitcanna-1"
CHAIN_DENOM="ubcna"
BINARY_NAME="bcnad"
BINARY_VERSION_TAG="v1.5.3"
CHEAT_SHEET="https://nodejumper.io/bitcanna/cheat-sheet"

printLine
echo -e "Node moniker:        ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:            ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:         ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag:  ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf bcna
git clone https://github.com/BitCannaGlobal/bcna.git
cd bcna || return
git checkout v1.5.3
make install
bcnad version # 1.5.3

bcnad config chain-id $CHAIN_ID
bcnad init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/BitCannaGlobal/bcna/main/genesis.json > $HOME/.bcna/config/genesis.json
curl -s https://snapshots1.nodejumper.io/bitcanna/addrbook.json > $HOME/.bcna/config/addrbook.json

SEEDS="d6aa4c9f3ccecb0cc52109a95962b4618d69dd3f@seed1.bitcanna.io:26656,23671067d0fd40aec523290585c7d8e91034a771@seed2.bitcanna.io:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.bcna/config/config.toml

PRUNING_INTERVAL=$(shuf -n1 -e 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97)
sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.bcna/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.bcna/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "'$PRUNING_INTERVAL'"|g' $HOME/.bcna/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 10000|g' $HOME/.bcna/config/app.toml

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

SNAP_RPC="https://bitcanna.nodejumper.io:443"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000))
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i 's|^enable *=.*|enable = true|' $HOME/.bcna/config/config.toml
sed -i 's|^rpc_servers *=.*|rpc_servers = "'$SNAP_RPC,$SNAP_RPC'"|' $HOME/.bcna/config/config.toml
sed -i 's|^trust_height *=.*|trust_height = '$BLOCK_HEIGHT'|' $HOME/.bcna/config/config.toml
sed -i 's|^trust_hash *=.*|trust_hash = "'$TRUST_HASH'"|' $HOME/.bcna/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable bcnad
sudo systemctl start bcnad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
