#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="uptick_7000-1"
CHAIN_DENOM="auptick"
BINARY="uptickd"
CHEAT_SHEET="https://nodejumper.io/uptick-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

curl -L https://download.uptick.network/download/uptick/testnet/release/v0.2.3/v0.2.3.tar.gz > uptick.tar.gz
tar -xvzf uptick.tar.gz
sudo mv -f uptick-v0.2.3/linux/uptickd /usr/local/bin/uptickd
rm -rf uptick.tar.gz
rm -rf uptick-v0.2.3
uptickd version # v0.2.3

uptickd config keyring-backend test
uptickd config chain-id $CHAIN_ID
uptickd init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/UptickNetwork/uptick-testnet/main/uptick_7000-1/genesis.json > $HOME/.uptickd/config/genesis.json
sha256sum $HOME/.uptickd/config/genesis.json # 9c2a5a9eb74103e3a9ae0599f66b9e665bdd7d67c178ab8308f853602b73be75

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001auptick"|g' $HOME/.uptickd/config/app.toml
seeds="61f9e5839cd2c56610af3edd8c3e769502a3a439@seed0.testnet.uptick.network:26656"
peers="ce7e61b565292d6606fc0fbf4b2bc364227a1ef0@uptick-testnet.nodejumper.io:30656,eecdfb17919e59f36e5ae6cec2c98eeeac05c0f2@peer0.testnet.uptick.network:26656,178727600b61c055d9b594995e845ee9af08aa72@peer1.testnet.uptick.network:26656,61f9e5839cd2c56610af3edd8c3e769502a3a439@seed0.testnet.uptick.network:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.uptickd/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "nothing"|g' $HOME/.uptickd/config/app.toml
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

cd "$HOME/.uptickd" || return
rm -rf data

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/uptick-testnet/ | egrep -o ">uptick_7000-1.*\.tar.lz4" | tr -d ">")
curl https://snapshots1-testnet.nodejumper.io/uptick-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf - -C $HOME/.uptickd

sudo systemctl daemon-reload
sudo systemctl enable uptickd
sudo systemctl restart uptickd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
