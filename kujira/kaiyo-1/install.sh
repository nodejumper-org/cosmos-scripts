#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="kaiyo-1"
CHAIN_DENOM="ukuji"
BINARY_NAME="kujirad"
BINARY_VERSION_TAG="v0.9.0"
CHEAT_SHEET="https://nodejumper.io/kujira/cheat-sheet"

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
rm -rf core
git clone https://github.com/Team-Kujira/core.git
cd core || return
git checkout v0.9.0
make install

kujirad config chain-id $CHAIN_ID
kujirad init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/Team-Kujira/networks/master/mainnet/kaiyo-1.json > $HOME/.kujira/config/genesis.json
curl -s https://snapshots.nodejumper.io/kujira/addrbook.json > $HOME/.kujira/config/addrbook.json

SEEDS="63158c2af0d639d8105a8e6ca2c53dc243dd156f@seed.kujira.mintserve.org:31897,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:18656,400f3d9e30b69e78a7fb891f60d76fa3c73f0ecc@kujira.rpc.kjnodes.com:13659"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.kujira/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.kujira/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.kujira/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "17"|g' $HOME/.kujira/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.kujira/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.0001ukuji,0.00150factory/kujira1qk00h5atutpsv900x202pxx42npjr9thg58dnqpa72f2p7m2luase444a7/uusk,0.00150ibc/295548A78785A1007F232DE286149A6FF512F180AF5657780FC89C009E2C348F,0.000125ibc/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2,0.00126ibc/47BD209179859CDE4A2806763D7189B6E6FE13A17880FE2B42DE1E6C1E329E23,0.00652ibc/3607EB5B5E64DD1C0E12E07F077FF470D5BC4706AFCBC98FE1BA960E5AE4CE07,617283951ibc/F3AA7EF362EC5E791FE78A0F4CCC69FEE1F9A7485EB1A8CAB3F6601C00522F10,0.000288ibc/EFF323CC632EC4F747C61BCE238A758EFDB7699C3226565F7C20DA06509D59A5,0.000125ibc/DA59C009A0B3B95E0549E6BF7B075C8239285989FF457A8EDDBB56F10B2A6986,0.00137ibc/A358D7F19237777AF6D8AD0E0F53268F8B18AE8A53ED318095C14D6D7F3B2DB5,0.0488ibc/4F393C3FCA4190C0A6756CE7F6D897D5D1BE57D6CCB80D0BC87393566A7B6602,78492936ibc/004EBF085BBED1029326D56BE8A2E67C08CECE670A94AC1947DF413EF5130EB2,964351ibc/1B38805B1C75352B28169284F96DF56BDEBD9E8FAC005BDCC8CF0378C82AA8E7\"|' $HOME/.kujira/config/app.toml
sed -i 's|^timeout_commit =.*|timeout_commit = "1500ms"|g' $HOME/.kujira/config/config.toml
sed -i 's|^prometheus *=.*|prometheus = true|g' $HOME/.kujira/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/kujirad.service > /dev/null << EOF
[Unit]
Description=Kujira Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which kujirad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

kujirad tendermint unsafe-reset-all --home $HOME/.kujira --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots.nodejumper.io/kujira/info.json | jq -r .fileName)
curl "https://snapshots.nodejumper.io/kujira/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.kujira"

sudo systemctl daemon-reload
sudo systemctl enable kujirad
sudo systemctl start kujirad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
