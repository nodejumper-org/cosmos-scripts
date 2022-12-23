#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="atlantic-1"
CHAIN_DENOM="usei"
BINARY="seid"
CHEAT_SHEET="https://nodejumper.io/sei-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf sei-chain
git clone https://github.com/sei-protocol/sei-chain.git
cd sei-chain || return
git checkout 1.2.2beta-postfix
make install
seid version # 1.2.2beta-postfix

seid config keyring-backend test
seid config chain-id $CHAIN_ID
seid init $NODE_MONIKER --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/sei-protocol/testnet/main/sei-incentivized-testnet/genesis.json > $HOME/.sei/config/genesis.json
sha256sum $HOME/.sei/config/genesis.json #4ae7193446b53d78bb77cab1693a6ddf6c1fe58c9693ed151e71f43956fdb3f7

curl -s https://raw.githubusercontent.com/sei-protocol/testnet/main/sei-incentivized-testnet/addrbook.json > $HOME/.sei/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001usei"|g' $HOME/.sei/config/app.toml
seeds="df1f6617ff5acdc85d9daa890300a57a9d956e5e@sei-atlantic-1.seed.rhinostake.com:16660"
peers=""
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.sei/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.sei/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.sei/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.sei/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/seid.service > /dev/null << EOF
[Unit]
Description=Sei Protocol Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which seid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

seid tendermint unsafe-reset-all --home $HOME/.sei --keep-addr-book

SNAP_RPC="https://sei-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.sei/config/config.toml

curl https://snapshots1-testnet.nodejumper.io/sei-testnet/wasm.lz4 | lz4 -dc - | tar -xf - -C $HOME/.sei

sudo systemctl daemon-reload
sudo systemctl enable seid
sudo systemctl restart seid

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
