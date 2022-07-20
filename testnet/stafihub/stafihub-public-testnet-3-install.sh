#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="stafihub-public-testnet-3"
CHAIN_DENOM="ufis"
BINARY="stafihubd"
CHEAT_SHEET="https://nodejumper.io/stafihub-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}testnet-1.0.3${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

bash <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "Building binaries..." && sleep 1

cd || return
rm -rf stafihub
git clone https://github.com/stafihub/stafihub
cd stafihub || return
git checkout public-testnet-v3
make install
stafihubd version # nothing is printed

# replace nodejumper with your own moniker, if you'd like
stafihubd config chain-id stafihub-public-testnet-3
stafihubd init $NODE_MONIKER --chain-id stafihub-public-testnet-3

curl https://raw.githubusercontent.com/stafihub/network/main/testnets/stafihub-public-testnet-3/genesis.json > $HOME/.stafihub/config/genesis.json
sha256sum $HOME/.stafihub/config/genesis.json # 364d5c18b18d3a1d3fcc9125f855610f66c28b5df089ca1900376059273f4ef1

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ufis"|g' $HOME/.stafihub/config/app.toml
seeds=""
peers="4b5afbe0bd0d128f98943c0f2941976bd3fb0b9b@stafihub-testnet.nodejumper.io:26656,e906c21307a875c743806f1a92ecb50b5138480d@65.21.138.123:30656,3a440f9fd1a9138393e395028bd6079a187364c6@65.108.124.172:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.stafihub/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.stafihub/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.stafihub/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.stafihub/config/app.toml

printCyan "Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/stafihubd.service > /dev/null << EOF
[Unit]
Description=Stafihub Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which stafihubd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

stafihubd tendermint unsafe-reset-all --home $HOME/.stafihub --keep-addr-book

SNAP_RPC="https://stafihub-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.stafihub/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable stafihubd
sudo systemctl restart stafihubd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
