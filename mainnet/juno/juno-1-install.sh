#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="juno-1"
CHAIN_DENOM="ujuno"
BINARY="junod"
CHEAT_SHEET="https://nodejumper.io/juno/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1
cd || return
rm -rf juno
git clone https://github.com/CosmosContracts/juno
cd juno || return
git checkout v9.0.0
make install
junod version # v9.0.0

# setup cosmovisor
source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/cosmovisor_install.sh)
mkdir -p $HOME/.juno/cosmovisor/upgrades/v9.0.0/bin
rm $HOME/.juno/cosmovisor/current
ln -s $HOME/.juno/cosmovisor/upgrades/v9.0.0 $HOME/.juno/cosmovisor/current
mv $HOME/go/bin/junod $HOME/.juno/cosmovisor/upgrades/v9.0.0/bin
addToPath "$HOME/.juno/cosmovisor/current/bin"
source $HOME/.bash_profile

junod config chain-id $CHAIN_ID
junod init $NODE_MONIKER --chain-id $CHAIN_ID

cd || return
curl -# -L https://share.blockpane.com/juno/phoenix/genesis.json >$HOME/.juno/config/genesis.json
sha256sum $HOME/.juno/config/genesis.json # 1839fcf10ade35b81aad83bc303472bd0e9832efb0ab2382b382e3cc07b265e0

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0025ujuno,0.001ibc\/C4CFF46FD6DE35CA4CF4CE031E643C8FDC9BA4B99AE598E9B0ED98FE3A2319F9"|g' $HOME/.juno/config/app.toml
seeds=""
peers="$(curl -sL "https://raw.githubusercontent.com/CosmosContracts/mainnet/main/$CHAIN_ID/persistent_peers.txt")"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.juno/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.juno/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.juno/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.juno/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/junod.service >/dev/null <<EOF
[Unit]
Description=Juno Daemon (cosmovisor)
After=network-online.target
[Service]
User=${USER}
ExecStart=$(which cosmovisor) run start
Restart=always
RestartSec=3
LimitNOFILE=4096
Environment="DAEMON_NAME=junod"
Environment="DAEMON_HOME=${HOME}/.juno"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true
Environment="DAEMON_LOG_BUFFER_SIZE=512"
[Install]
WantedBy=multi-user.target
EOF

junod tendermint unsafe-reset-all --home $HOME/.juno --keep-addr-book

SNAP_RPC="https://juno.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000))
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.juno/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable junod
sudo systemctl restart junod

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
