#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="axelar-testnet-lisbon-3"
CHAIN_DENOM="uaxl"
BINARY="axelard"
AXELAR_VERSION="v0.26.5"
TOFND_VERSION="v0.10.1"
CHEAT_SHEET="https://nodejumper.io/axelar-testnet/cheat-sheet"

printLine
echo -e "Node moniker:    ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:        ${CYAN}$CHAIN_ID${NC}"
echo -e "axelard version: ${CYAN}$AXELAR_VERSION${NC}"
echo -e "tofnd version:   ${CYAN}$TOFND_VERSION${NC}"
echo -e "Chain demon:     ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

# build axelard
cd || return
rm -rf axelar-core
git clone https://github.com/axelarnetwork/axelar-core.git
cd axelar-core || return
git checkout $AXELAR_VERSION
make install
axelar version

# build tofnd
cd || return
rm -rf tofnd
git clone https://github.com/axelarnetwork/tofnd.git
cd tofnd || return
git checkout $TOFND_VERSION
make install
tofnd version

axelard config chain-id $CHAIN_ID
axelard init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/axelarnetwork/axelarate-community/main/configuration/app.toml > $HOME/.axelar_testnet/config/app.toml
curl https://raw.githubusercontent.com/axelarnetwork/axelarate-community/main/configuration/config.toml > $HOME/.axelar_testnet/config/config.toml
curl https://raw.githubusercontent.com/axelarnetwork/axelarate-community/main/resources/testnet/seeds.toml > $HOME/.axelar_testnet/config/seeds.toml
curl https://raw.githubusercontent.com/axelarnetwork/axelarate-community/main/resources/testnet/genesis.json > $HOME/.axelar_testnet/config/genesis.json

sha256sum $HOME/.axelar_testnet/config/genesis.json # TODO: check sha256sum

sed -i.bak 's/external_address = ""/external_address = "'"$(curl -4 ifconfig.co)"':26656"/g' $HOME/.axelar/config/config.toml

#sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uan1"|g' $HOME/.axelar_testnet/config/app.toml
#seeds="a005b8923888007eb5cf9ed8c8120ed956bc31f7@k8s-testnet-axelarco-c0dd71f944-b4c8da2f814e7b8f.elb.us-east-2.amazonaws.com:26656"
#peers="2b540c43d640befc35959eb062c8505612b7d67f@another1-testnet.nodejumper.io:26656"
#sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.axelar_testnet/config/config.toml

# TODO: CHECK POSSIBILITY TO PRUNING
# in case of pruning
#sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.axelar_testnet/config/app.toml
#sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.axelar_testnet/config/app.toml
#sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.axelar_testnet/config/app.toml

printCyan "5. Starting services and synchronization..." && sleep 1

sudo tee /etc/systemd/system/axelard.service > /dev/null << EOF
[Unit]
Description=Axelard Cosmos daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which axelard) start --home $HOME/.axelar_testnet
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/tofnd.service > /dev/null << EOF
[Unit]
Description=Tofnd daemon
After=network-online.target

[Service]
User=$USER
ExecStart=/usr/bin/sh -c 'echo $KEYRING_PASSWORD | $(which tofnd) -m existing -d $HOME/.tofnd'
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# TODO: SAVE VALIDATOR_OPERATOR_ADDRESS TO VARIABLE
sudo tee /etc/systemd/system/vald.service >/dev/null << EOF
[Unit]
Description=Vald daemon
After=network-online.target
[Service]
User=$USER
ExecStart=/usr/bin/sh -c 'echo $KEYRING_PASSWORD | $(which axelard) vald-start --validator-addr $VALIDATOR_OPERATOR_ADDRESS --log_level debug --chain-id $CHAIN_ID --from broadcaster'
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

axelard unsafe-reset-all

SNAP_RPC="https://another1-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.axelar_testnet/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable axelard
sudo systemctl enable tofnd
sudo systemctl enable vald
sudo systemctl restart axelard
sudo systemctl restart tofnd
sudo systemctl restart vald

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
