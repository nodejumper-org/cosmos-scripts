#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="nois-testnet-003"
CHAIN_DENOM="unois"
BINARY="noisd"
CHEAT_SHEET="https://nodejumper.io/nois-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf full-node
git clone https://github.com/noislabs/full-node.git
cd full-node/full-node/ || return
git checkout nois-testnet-003
./build.sh
mkdir -p $HOME/go/bin
sudo mv out/noisd $HOME/go/bin/noisd
noisd version # 0.29.0-rc2

ollod config keyring-backend test
ollod config chain-id $CHAIN_ID
ollod init $NODE_MONIKER --chain-id $CHAIN_ID

curl -# https://raw.githubusercontent.com/noislabs/testnets/main/nois-testnet-003/genesis.js > $HOME/.noisd/config/genesis.json
sha256sum $HOME/.noisd/config/genesis.json # todo: check hash

curl -s https://snapshots2-testnet.nodejumper.io/ollo-testnet/addrbook.json > $HOME/.noisd/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.005unois"|g' $HOME/.noisd/config/app.toml
seeds=""
peers="xxxxxxx@nois-testnet.nodejumper.io:28656,bf5bbdf9ac1ccd72d7b29c3fbcc7e99ff89fd053@node-0.noislabs.com:26656" # todo: set persistent peers
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.noisd/config/config.toml

# set custom timeouts
sed -i 's|^timeout_propose =.*$|timeout_propose = "2000ms"|' $HOME/.noisd/config.toml
sed -i 's|^timeout_propose_delta =.*$|timeout_propose_delta = "500ms"|' $HOME/.noisd/config.toml
sed -i 's|^timeout_prevote =.*$|timeout_prevote = "1s"|' $HOME/.noisd/config.toml
sed -i 's|^timeout_prevote_delta =.*$|timeout_prevote_delta = "500ms"|' $HOME/.noisd/config.toml
sed -i 's|^timeout_precommit =.*$|timeout_precommit = "1s"|' $HOME/.noisd/config.toml
sed -i 's|^timeout_precommit_delta =.*$|timeout_precommit_delta = "500ms"|' $HOME/.noisd/config.toml
sed -i 's|^timeout_commit =.*$|timeout_commit = "1800ms"|' $HOME/.noisd/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.noisd/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.noisd/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "13"|g' $HOME/.noisd/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/noisd.service > /dev/null << EOF
[Unit]
Description=Noisd Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which noisd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

noisd tendermint unsafe-reset-all --home $HOME/.noisd --keep-addr-book

SNAP_RPC="https://nois-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.noisd/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable noisd
sudo systemctl restart noisd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
