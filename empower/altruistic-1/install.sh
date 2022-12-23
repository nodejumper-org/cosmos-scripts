#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="altruistic-1"
CHAIN_DENOM="umpwr"
BINARY="empowerd"
CHEAT_SHEET="https://nodejumper.io/empower-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf empowerchain
git clone https://github.com/empowerchain/empowerchain
cd empowerchain/chain || return
git checkout v0.0.3
make install
empowerd version # 0.0.3

empowerd config keyring-backend test
empowerd config chain-id $CHAIN_ID
empowerd init $NODE_MONIKER --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/empowerchain/empowerchain/main/testnets/altruistic-1/genesis.json > $HOME/.empowerchain/config/genesis.json
sha256sum $HOME/.empowerchain/config/genesis.json # fcae4a283488be14181fdc55f46705d9e11a32f8e3e8e25da5374914915d5ca8

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.025umpwr"|g' $HOME/.empowerchain/config/app.toml
seeds=""
peers="ca8b9d5fecd3258cb8bb4164017114898cd63ad5@empower-testnet.nodejumper.io:31656,6dae9286b4ef23151148922befc0f32a00cc1ec4@65.21.134.202:26656,ab4b4331d161cf0e98d3244e30225e4f38ac8d2f@65.109.28.177:44656,d9307a7ba665a54e65f4fa5dbb5401448e1c3456@65.109.30.117:30656,46b552c62df0523a2bfff285eb384e4b197484aa@65.21.133.125:33656,408980a63332b230a90ad549e93162dab303836f@65.108.225.158:17456,605b175a3cf6f71d454840baef08d0e81d94935f@65.108.52.192:46656,86669cd5e5914f862578d43de483f49e93d396b1@51.83.35.129:26656,b405572f7bf70f681d1e82f196e1399bf90a9d8a@138.201.197.163:26656,c5d44acd2f0ee122352d2f8154d9b29aeb9bf0ec@159.69.65.97:36656,2b3da30140b57d64a57a25485c237f9c7c3c3324@194.163.136.90:26656,8abceaabc650d81a751e40382f80af6c98ba466f@185.239.209.180:35656,333de3fc2eba7eead24e0c5f53d665662b2ba001@35.187.86.119:26656,b5df76282e8704d253012688613d4eb725d3cb12@77.37.176.99:56656,8498049b61177a53b3f0e6b8f7c4a574251a2bbb@149.102.157.96:36656,56d05d4ae0e1440ad7c68e52cc841c424d59badd@96.234.160.22:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.empowerchain/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.empowerchain/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.empowerchain/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.empowerchain/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.empowerchain/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/empowerd.service > /dev/null << EOF
[Unit]
Description=Empower Chain Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which empowerd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

empowerd tendermint unsafe-reset-all --home $HOME/.empowerchain --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots2-testnet.nodejumper.io/empower-testnet/ | egrep -o ">altruistic-1.*\.tar.lz4" | tr -d ">")
curl https://snapshots2-testnet.nodejumper.io/empower-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf - -C $HOME/.empowerchain

sudo systemctl daemon-reload
sudo systemctl enable empowerd
sudo systemctl restart empowerd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"