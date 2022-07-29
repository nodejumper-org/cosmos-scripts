#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="paloma-testnet-6"
CHAIN_DENOM="ugrain"
BINARY="palomad"
CHEAT_SHEET="https://nodejumper.io/paloma-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1
cd || return
curl -L https://github.com/CosmWasm/wasmvm/raw/main/api/libwasmvm.x86_64.so > libwasmvm.x86_64.so
sudo mv -f libwasmvm.x86_64.so /usr/lib/libwasmvm.x86_64.so
curl -L https://github.com/palomachain/paloma/releases/download/v0.4.0-alpha/paloma_0.4.0-alpha_Linux_x86_64.tar.gz > paloma.tar.gz
tar -xvzf paloma.tar.gz
rm -rf paloma.tar.gz
sudo mv -f palomad /usr/local/bin/palomad
palomad version # v0.4.0-alpha

palomad config chain-id $CHAIN_ID
palomad init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-6/genesis.json > $HOME/.paloma/config/genesis.json
sha256sum $HOME/.paloma/config/genesis.json # ad6d37a6ee49f0d04cb84150337968db6092ce1d2c10b5719eff52d73a12e34f

curl https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-6/addrbook.json > $HOME/.paloma/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ugrain"|g' $HOME/.paloma/config/app.toml
seeds=""
peers="484e0d3cc02ba868d4ad68ec44caf89dd14d1845@paloma-testnet.nodejumper.io:33656,8fab1d100d1c01de299788758d31d36c321c23b5@144.202.103.140:26656,8fab1d100d1c01de299788758d31d36c321c23b5@144.202.103.140:26656,1f74adfbfa794a53b104368fcb1189eddc18d66f@173.255.229.106:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.paloma/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.paloma/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.paloma/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.paloma/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.paloma/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/palomad.service > /dev/null << EOF
[Unit]
Description=Paloma Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which palomad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

palomad tendermint unsafe-reset-all --home $HOME/.paloma

#SNAP_RPC="https://paloma-testnet.nodejumper.io:443"
#LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
#BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
#TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
#
#echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH
#
#sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
#s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
#s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
#s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.paloma/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable palomad
sudo systemctl restart palomad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
