#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="galileo-3"
CHAIN_DENOM="uandr"
BINARY_NAME="andromedad"
BINARY_VERSION_TAG="galileo-3-v1.1.0-beta1"
CHEAT_SHEET="https://nodejumper.io/andromeda-testnet/cheat-sheet"

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
rm -rf andromedad
git clone https://github.com/andromedaprotocol/andromedad.git
cd andromedad || return
git checkout galileo-3-v1.1.0-beta1
make install
andromedad version # todo: check version

andromedad config keyring-backend test
andromedad config chain-id $CHAIN_ID
andromedad init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -L https://raw.githubusercontent.com/andromedaprotocol/testnets/galileo-3/genesis.json > $HOME/.andromedad/config/genesis.json
curl -s https://snapshots-testnet.nodejumper.io/andromeda-testnet/addrbook.json > $HOME/.andromedad/config/addrbook.json

SEEDS=""
PEERS="06d4ab2369406136c00a839efc30ea5df9acaf11@10.128.0.44:26656,43d667323445c8f4d450d5d5352f499fa04839a8@192.168.0.237:26656,29a9c5bfb54343d25c89d7119fade8b18201c503@192.168.101.79:26656,6006190d5a3a9686bbcce26abc79c7f3f868f43a@37.252.184.230:26656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.andromedad/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.andromedad/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.andromedad/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.andromedad/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 2000|g' $HOME/.andromedad/config/app.toml
sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uandr"|g' $HOME/.andromedad/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.andromedad/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/andromedad.service > /dev/null << EOF
[Unit]
Description=Andromeda testnet Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which andromedad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF


# todo: add state-sync
#andromedad tendermint unsafe-reset-all --home $HOME/.andromedad --keep-addr-book
#
#SNAP_RPC="https://andromeda-testnet.nodejumper.io:443"
#LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
#BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000))
#TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
#
#echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH
#
#sed -i 's|^enable *=.*|enable = true|' $HOME/.andromedad/config/config.toml
#sed -i 's|^rpc_servers *=.*|rpc_servers = "'$SNAP_RPC,$SNAP_RPC'"|' $HOME/.andromedad/config/config.toml
#sed -i 's|^trust_height *=.*|trust_height = '$BLOCK_HEIGHT'|' $HOME/.andromedad/config/config.toml
#sed -i 's|^trust_hash *=.*|trust_hash = "'$TRUST_HASH'"|' $HOME/.andromedad/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable andromedad
sudo systemctl start andromedad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
