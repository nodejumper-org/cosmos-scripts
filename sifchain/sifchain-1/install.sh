#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="sifchain-1"
CHAIN_DENOM="rowan"
BINARY_NAME="sifnoded"
BINARY_VERSION_TAG="v1.0-beta.12-issuefix"
CHEAT_SHEET="https://nodejumper.io/sifchain/cheat-sheet"

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
rm -rf sifnode
git clone https://github.com/Sifchain/sifnode.git
cd sifnode || return
git checkout v1.0-beta.12-issuefix
make install
sifnoded version # 1.0-beta.12

sifnoded init "$NODE_MONIKER" --chain-id $CHAIN_ID
sed -i 's|^chain-id *=.*|chain-id = "'$CHAIN_ID'"|g' $HOME/.sifnoded/config/client.toml

curl -s https://raw.githubusercontent.com/Sifchain/networks/master/betanet/sifchain-1/genesis.json.gz > ~/.sifnoded/config/genesis.zip
gunzip -c ~/.sifnoded/config/genesis.zip > ~/.sifnoded/config/genesis.json
rm -rf ~/.sifnoded/config/genesis.zip

curl -s https://snapshots3.nodejumper.io/sifchain/addrbook.json > $HOME/.sifnoded/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.sifnoded/config/config.toml

PRUNING_INTERVAL=$(shuf -n1 -e 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97)
sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.sifnoded/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.sifnoded/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "'$PRUNING_INTERVAL'"|g' $HOME/.sifnoded/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 2000|g' $HOME/.sifnoded/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001rowan"|g' $HOME/.sifnoded/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.sifnoded/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/sifnoded.service > /dev/null << EOF
[Unit]
Description=Sifchain Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which sifnoded) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

sifnoded tendermint unsafe-reset-all --home $HOME/.sifnoded --keep-addr-book

SNAP_RPC="https://sifchain.nodejumper.io:443"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000))
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i 's|^enable *=.*|enable = true|' $HOME/.sifnoded/config/config.toml
sed -i 's|^rpc_servers *=.*|rpc_servers = "'$SNAP_RPC,$SNAP_RPC'"|' $HOME/.sifnoded/config/config.toml
sed -i 's|^trust_height *=.*|trust_height = '$BLOCK_HEIGHT'|' $HOME/.sifnoded/config/config.toml
sed -i 's|^trust_hash *=.*|trust_hash = "'$TRUST_HASH'"|' $HOME/.sifnoded/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable sifnoded
sudo systemctl start sifnoded

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
