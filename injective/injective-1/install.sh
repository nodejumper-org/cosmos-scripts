#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="injective-1"
CHAIN_DENOM="inj"
BINARY_NAME="injectived"
CHEAT_SHEET="https://nodejumper.io/injective/cheat-sheet"
BINARY_VERSION_TAG="v1.11.5-1687535916"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag:  ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
wget https://github.com/InjectiveLabs/injective-chain-releases/releases/download/v1.11.5-1687535916/linux-amd64.zip
unzip linux-amd64.zip
sudo mv peggo /usr/bin
sudo mv injectived /usr/bin
sudo mv libwasmvm.x86_64.so /usr/lib
rm linux-amd64.zip

injectived config chain-id $CHAIN_ID
injectived init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/InjectiveLabs/mainnet-config/master/10001/genesis.json > $HOME/.injectived/config/genesis.json

SEEDS="38c18461209694e1f667ff2c8636ba827cc01c86@176.9.143.252:11751,4f9025feca44211eddc26cd983372114947b2e85@176.9.140.49:11751,c98bb1b889ddb58b46e4ad3726c1382d37cd5609@65.109.51.80:11751,23d0eea9bb42316ff5ea2f8b4cd8475ef3f35209@65.109.36.70:11751,f9ae40fb4a37b63bea573cc0509b4a63baa1a37a@15.235.114.80:11751,7f3473ddab10322b63789acb4ac58647929111ba@15.235.13.116:11751,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:14356,ebc272824924ea1a27ea3183dd0b9ba713494f83@injective-mainnet-seed.autostake.com:26726,1846e76e14913124a07e231586d487a0636c0296@tenderseed.ccvalidators.com:26007"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.injectived/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.injectived/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.injectived/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "17"|g' $HOME/.injectived/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.injectived/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "500000000inj"|g' $HOME/.injectived/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.injectived/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/injectived.service > /dev/null << EOF
[Unit]
Description=Injective Node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=/usr/bin
ExecStart=/bin/bash -c '/usr/bin/injectived --log-level=error start'
Restart=always
RestartSec=5
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

injectived tendermint unsafe-reset-all --home $HOME/.injectived --keep-addr-book

nohup sudo aws s3 sync --no-sign-request --delete s3://injective-snapshots/mainnet/pruned/injectived/data $HOME/.injectived/data
nohup sudo aws s3 sync --no-sign-request --delete s3://injective-snapshots/mainnet/pruned/injectived/wasm $HOME/.injectived/wasm

sudo systemctl daemon-reload
sudo systemctl enable injectived
sudo systemctl start injectived

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
