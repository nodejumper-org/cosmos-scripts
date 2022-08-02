#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="STRIDE-TESTNET-2"
CHAIN_DENOM="ustrd"
BINARY="strided"
CHEAT_SHEET="https://nodejumper.io/stride-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf stride
git clone https://github.com/Stride-Labs/stride.git
cd stride || return
git checkout 3cb77a79f74e0b797df5611674c3fbd000dfeaa1
make build
mkdir -p $HOME/go/bin
sudo cp $HOME/stride/build/strided $HOME/go/bin
strided version #

strided config chain-id $CHAIN_ID
strided init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/Stride-Labs/testnet/main/poolparty/genesis.json > $HOME/.stride/config/genesis.json
sha256sum $HOME/.stride/config/genesis.json # d6204cd1e90e74bb29e9e0637010829738fa5765869288aa29a12ed83e2847ea

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ustrd"|g' $HOME/.stride/config/app.toml
seeds="c0b278cbfb15674e1949e7e5ae51627cb2a2d0a9@seedv2.poolparty.stridenet.co:26656"
peers="17b24705533d633cb3501233a18912ae6cc36a41@stride-testnet.nodejumper.io:28656,48b1310bc81deea3eb44173c5c26873c23565d33@stride-testnet-2-node1.poolparty.stridenet.co:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.stride/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.stride/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.stride/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.stride/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.stride/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/strided.service > /dev/null << EOF
[Unit]
Description=Stride Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which strided) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

strided tendermint unsafe-reset-all --home $HOME/.stride/ --keep-addr-book

SNAP_RPC="https://stride-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.stride/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable strided
sudo systemctl restart strided

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
