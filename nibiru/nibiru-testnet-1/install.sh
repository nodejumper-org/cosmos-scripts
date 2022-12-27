#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="nibiru-testnet-1"
CHAIN_DENOM="unibi"
BINARY_NAME="nibid"
CHEAT_SHEET="https://nodejumper.io/nibiru-testnet/cheat-sheet"

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
rm -rf nibiru
git clone https://github.com/NibiruChain/nibiru
cd nibiru || return
git checkout v0.15.0
make install
nibid version # v0.15.0

nibid config keyring-backend test
nibid config chain-id $CHAIN_ID
nibid init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://rpc.testnet-1.nibiru.fi/genesis | jq -r .result.genesis > $HOME/.nibid/config/genesis.json
sha256sum $HOME/.nibid/config/genesis.json # b58b61beb34f0d9e45ec2f1449f6600acef428b401976dc90edb9d586a412ed2

curl -s https://snapshots3-testnet.nodejumper.io/nibiru-testnet/addrbook.json > $HOME/.nibid/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001unibi"|g' $HOME/.nibid/config/app.toml
seeds=""
peers="b32bb87364a52df3efcbe9eacc178c96b35c823a@nibiru-testnet.nodejumper.io:26656,968472e8769e0470fadad79febe51637dd208445@65.108.6.45:60656,ff597c3eea5fe832825586cce4ed00cb7798d4b5@rpc.nibiru.ppnv.space:10656,37713248f21c37a2f022fbbb7228f02862224190@35.243.130.198:26656,ff59bff2d8b8fb6114191af7063e92a9dd637bd9@35.185.114.96:26656,cb431d789fe4c3f94873b0769cb4fce5143daf97@35.227.113.63:26656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.nibid/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.nibid/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.nibid/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.nibid/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/nibid.service > /dev/null << EOF
[Unit]
Description=Nibiru Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which nibid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

nibid tendermint unsafe-reset-all --home $HOME/.nibid --keep-addr-book

SNAP_RPC="https://nibiru-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.nibid/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable nibid
sudo systemctl start nibid

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
