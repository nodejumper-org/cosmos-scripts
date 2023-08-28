#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="nois-testnet-004"
CHAIN_DENOM="unois"
BINARY_NAME="noisd"
BINARY_VERSION_TAG="v0.6.0"
CHEAT_SHEET="https://nodejumper.io/nois-testnet/cheat-sheet"

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
rm -rf noisd
git clone https://github.com/noislabs/noisd.git
cd noisd
git checkout v0.6.0
make install
noisd version # 0.6.0

noisd config keyring-backend test
noisd config chain-id $CHAIN_ID
noisd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/noislabs/testnets/main/nois-testnet-004/genesis.json > $HOME/.noisd/config/genesis.json
curl -s https://snapshots-testnet.nodejumper.io/nois-testnet/addrbook.json > $HOME/.noisd/config/addrbook.json

SEEDS="72cd4222818d25da5206092c3efc2c0dd0ec34fe@161.97.96.91:36656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.noisd/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.noisd/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.noisd/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "13"|g' $HOME/.noisd/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.noisd/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.005unois"|g' $HOME/.noisd/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.noisd/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/noisd.service > /dev/null << EOF
[Unit]
Description=Noisd Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which noisd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

noisd tendermint unsafe-reset-all --home $HOME/.noisd --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots-testnet.nodejumper.io/nois-testnet/info.json | jq -r .fileName)
curl "https://snapshots-testnet.nodejumper.io/nois-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.noisd"

sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:38658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:38657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:7260\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:38656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":38660\"%" $HOME/.noisd/config/config.toml && sed -i.bak -e "s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:10290\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:10291\"%; s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:2517\"%" $HOME/.noisd/config/app.toml && sed -i.bak -e "s%^node = \"tcp://localhost:26657\"%node = \"tcp://localhost:38657\"%" $HOME/.noisd/config/client.toml

sudo systemctl daemon-reload
sudo systemctl enable noisd
sudo systemctl start noisd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
