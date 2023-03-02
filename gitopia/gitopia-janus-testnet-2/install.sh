#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="gitopia-janus-testnet-2"
CHAIN_DENOM="utlore"
BINARY_NAME="gitopiad"
BINARY_VERSION_TAG="v1.2.0"
CHEAT_SHEET="https://nodejumper.io/gitopia-testnet/cheat-sheet"

printLine
echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

curl https://get.gitopia.com | bash
sudo mv /tmp/tmpinstalldir/git-remote-gitopia /usr/local/bin/

cd || return
rm -rf gitopia
git clone gitopia://Gitopia/gitopia
cd gitopia || return
git checkout v1.2.0
make install
gitopiad version # v1.2.0

gitopiad config keyring-backend test
gitopiad config chain-id $CHAIN_ID
gitopiad init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://server.gitopia.com/raw/gitopia/testnets/master/gitopia-janus-testnet-2/genesis.json.gz > ~/.gitopia/config/genesis.zip
gunzip -c ~/.gitopia/config/genesis.zip > ~/.gitopia/config/genesis.json
rm -rf ~/.gitopia/config/genesis.zip

curl -s https://snapshots1-testnet.nodejumper.io/gitopia-testnet/addrbook.json > $HOME/.gitopia/config/addrbook.json

SEEDS="399d4e19186577b04c23296c4f7ecc53e61080cb@seed.gitopia.com:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.gitopia/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.gitopia/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.gitopia/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.gitopia/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 2000|g' $HOME/.gitopia/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001utlore"|g' $HOME/.gitopia/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.gitopia/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/gitopiad.service > /dev/null << EOF
[Unit]
Description=Gitopia Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which gitopiad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

gitopiad tendermint unsafe-reset-all --home $HOME/.gitopia --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/gitopia-testnet/info.json | jq -r .fileName)
curl "https://snapshots1-testnet.nodejumper.io/gitopia-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.gitopia"

sudo systemctl daemon-reload
sudo systemctl enable gitopiad
sudo systemctl start gitopiad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
