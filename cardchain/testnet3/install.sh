#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="Testnet3"
CHAIN_DENOM="ubpf"
BINARY_NAME="Cardchaind"
BINARY_VERSION_TAG="latest-8103a490"
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
curl -L https://github.com/DecentralCardGame/Cardchain/releases/download/v0.81/Cardchain_latest_linux_amd64.tar.gz > Cardchain_latest_linux_amd64.tar.gz
tar -xvzf Cardchain_latest_linux_amd64.tar.gz
chmod +x Cardchaind
mv Cardchaind $HOME/go/bin
rm Cardchain_latest_linux_amd64.tar.gz

Cardchaind config keyring-backend test
Cardchaind config chain-id $CHAIN_ID
Cardchaind init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/DecentralCardGame/Testnet/main/genesis.json > $HOME/.Cardchain/config/genesis.json
curl -s https://snapshots2-testnet.nodejumper.io/cardchain-testnet/addrbook.json > $HOME/.Cardchain/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.Cardchain/config/config.toml

PRUNING_INTERVAL=$(shuf -n1 -e 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97)
sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.Cardchain/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.Cardchain/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "'$PRUNING_INTERVAL'"|g' $HOME/.Cardchain/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 2000|g' $HOME/.Cardchain/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ubpf"|g' $HOME/.bcna/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.Cardchain/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/Cardchaind.service > /dev/null << EOF
[Unit]
Description=Cardchain Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which Cardchaind) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

Cardchain unsafe-reset-all

SNAP_RPC="https://cardchain-testnet.nodejumper.io:443"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height);
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000));
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i 's|^enable *=.*|enable = true|' $HOME/.Cardchain/config/config.toml
sed -i 's|^rpc_servers *=.*|rpc_servers = "'$SNAP_RPC,$SNAP_RPC'"|' $HOME/.Cardchain/config/config.toml
sed -i 's|^trust_height *=.*|trust_height = '$BLOCK_HEIGHT'|' $HOME/.Cardchain/config/config.toml
sed -i 's|^trust_hash *=.*|trust_hash = "'$TRUST_HASH'"|' $HOME/.Cardchain/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable Cardchaind
sudo systemctl start Cardchaind

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u ${BINARY_NAME} -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
