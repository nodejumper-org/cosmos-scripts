#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="ununifi-beta-v1"
CHAIN_DENOM="uguu"
BINARY_NAME="ununifid"
BINARY_VERSION_TAG="v2.2.0"
CHEAT_SHEET="https://nodejumper.io/ununifi/cheat-sheet"

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
rm -rf ununifi
git clone https://github.com/UnUniFi/chain ununifi
cd ununifi || return
git checkout v2.2.0
make install
ununifid version

ununifid config chain-id $CHAIN_ID
ununifid init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/UnUniFi/network/main/launch/ununifi-beta-v1/genesis.json > $HOME/.ununifi/config/genesis.json
curl -s https://snapshots1.nodejumper.io/ununifi/addrbook.json > $HOME/.ununifi/config/addrbook.json

SEEDS="fa38d2a851de43d34d9602956cd907eb3942ae89@a.ununifi.cauchye.net:26656,404ea79bd31b1734caacced7a057d78ae5b60348@b.ununifi.cauchye.net:26656,1357ac5cd92b215b05253b25d78cf485dd899d55@[2600:1f1c:534:8f02:7bf:6b31:3702:2265]:26656,25006d6b85daeac2234bcb94dafaa73861b43ee3@[2600:1f1c:534:8f02:a407:b1c6:e8f5:94b]:26656,caf792ed396dd7e737574a030ae8eabe19ecdf5c@[2600:1f1c:534:8f02:b0a4:dbf6:e50b:d64e]:26656,796c62bb2af411c140cf24ddc409dff76d9d61cf@[2600:1f1c:534:8f02:ca0e:14e9:8e60:989e]:26656,cea8d05b6e01188cf6481c55b7d1bc2f31de0eed@[2600:1f1c:534:8f02:ba43:1f69:e23a:df6b]:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.ununifi/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.ununifi/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.ununifi/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.ununifi/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.ununifi/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uguu"|g' $HOME/.ununifi/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.ununifi/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/ununifid.service > /dev/null << EOF
[Unit]
Description=UnUniFi Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which ununifid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

ununifid unsafe-reset-all

SNAP_NAME=$(curl -s https://snapshots1.nodejumper.io/ununifi/info.json | jq -r .fileName)
curl "https://snapshots1.nodejumper.io/ununifi/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C $HOME/.ununifi

sudo systemctl daemon-reload
sudo systemctl enable ununifid
sudo systemctl start ununifid

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
