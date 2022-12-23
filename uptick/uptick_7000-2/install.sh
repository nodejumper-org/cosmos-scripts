#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="uptick_7000-2"
CHAIN_DENOM="auptick"
BINARY="uptickd"
CHEAT_SHEET="https://nodejumper.io/uptick-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

curl -L -k https://github.com/UptickNetwork/uptick/releases/download/v0.2.4/uptick-linux-amd64-v0.2.4.tar.gz > uptick.tar.gz
tar -xvzf uptick.tar.gz
sudo mv -f uptick-linux-amd64-v0.2.4/uptickd /usr/local/bin/uptickd
rm -rf uptick.tar.gz
rm -rf uptick-v0.2.4
uptickd version # v0.2.4

uptickd config keyring-backend test
uptickd config chain-id $CHAIN_ID
uptickd init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/UptickNetwork/uptick-testnet/main/uptick_7000-2/genesis.json > $HOME/.uptickd/config/genesis.json
sha256sum $HOME/.uptickd/config/genesis.json # f96764c7ae1bc713b2acc87b5320f2d10ee26716b3daa6cc455cb3a3906f05c2

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001auptick"|g' $HOME/.uptickd/config/app.toml
seeds=""
peers="9ffdc3cd450758f09e1c31f2548c812a5c86f141@uptick-testnet.nodejumper.io:29656,eecdfb17919e59f36e5ae6cec2c98eeeac05c0f2@peer0.testnet.uptick.network:26656,178727600b61c055d9b594995e845ee9af08aa72@peer1.testnet.uptick.network:26656,94b63fddfc78230f51aeb7ac34b9fb86bd042a77@uptick-testnet-rpc.p2p.brocha.in:30556"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.uptickd/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.uptickd/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.uptickd/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.uptickd/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.uptickd/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/uptickd.service > /dev/null << EOF
[Unit]
Description=Uptick Network Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which uptickd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

uptickd tendermint unsafe-reset-all --home $HOME/.uptickd/ --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/uptick-testnet/ | egrep -o ">uptick_7000-2.*\.tar.lz4" | tr -d ">")
curl https://snapshots1-testnet.nodejumper.io/uptick-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf - -C $HOME/.uptickd

sudo systemctl daemon-reload
sudo systemctl enable uptickd
sudo systemctl restart uptickd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
