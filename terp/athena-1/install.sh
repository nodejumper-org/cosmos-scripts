#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="athena-1"
CHAIN_DENOM="upersy"
BINARY="terpd"
CHEAT_SHEET="https://nodejumper.io/terpnetwork/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf terp-core
git clone https://github.com/terpnetwork/terp-core.git
cd terp-core || return
git checkout v0.1.0
make install
terpd version # v0.1.0

terpd config chain-id $CHAIN_ID
terpd init $NODE_MONIKER --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/terpnetwork/test-net/master/athena-1/genesis.json > $HOME/.terp/config/genesis.json
sha256sum $HOME/.terp/config/genesis.json # b1c07c8ced6289d7e92c3a47085a92296090907c598368baed390e9349699c82

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "120upersy"|g' $HOME/.terp/config/app.toml
seeds=""
peers="15f5bc75be9746fd1f712ca046502cae8a0f6ce7@terp-testnet.nodejumper.io:26656,7e5c0b9384a1b9636f1c670d5dc91ba4721ab1ca@23.88.53.28:36656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.terp/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.terp/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.terp/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.terp/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.terp/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/terpd.service > /dev/null << EOF
[Unit]
Description=TerpNetwork Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which terpd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

terpd tendermint unsafe-reset-all --home $HOME/.terp --keep-addr-book

cd "$HOME/.terp" || return
rm -rf data

SNAP_NAME=$(curl -s https://snapshots2-testnet.nodejumper.io/terp-testnet/ | egrep -o ">athena-1.*\.tar.lz4" | tr -d ">")
curl https://snapshots2-testnet.nodejumper.io/terp-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf -

sudo systemctl daemon-reload
sudo systemctl enable terpd
sudo systemctl restart terpd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
