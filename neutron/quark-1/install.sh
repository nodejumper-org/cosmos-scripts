#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="quark-1"
CHAIN_DENOM="untrn"
BINARY_NAME="neutrond"
BINARY_VERSION_TAG="v0.1.0"
CHEAT_SHEET="https://nodejumper.io/neutron-testnet/cheat-sheet"

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
rm -rf neutron
git clone https://github.com/neutron-org/neutron.git
cd neutron || return
git checkout v0.1.0
make install
neutrond version # v0.1.0

neutrond config keyring-backend test
neutrond config chain-id $CHAIN_ID
neutrond init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/neutron-org/testnets/main/quark/genesis.json > $HOME/.neutrond/config/genesis.json
sha256sum $HOME/.neutrond/config/genesis.json # 357c4d33fad26c001d086c0705793768ef32c884a6ba4aa73237ab03dd0cc2b4

curl -s https://snapshots3-testnet.nodejumper.io/neutron-testnet/addrbook.json > $HOME/.neutrond/config/addrbook.json

# seeds and peers
sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001untrn"|g' $HOME/.neutrond/config/app.toml
seeds="e2c07e8e6e808fb36cca0fc580e31216772841df@seed-1.quark.ntrn.info:26656,c89b8316f006075ad6ae37349220dd56796b92fa@tenderseed.ccvalidators.com:29001"
peers="6369a00a9b60ec53a1e76435f88cba798c9a9b9c@neutron-testnet.nodejumper.io:26656,fcde59cbba742b86de260730d54daa60467c91a5@23.109.158.180:26656,5bdc67a5d5219aeda3c743e04fdcd72dcb150ba3@65.109.31.114:2480,3e9656706c94ae8b11596e53656c80cf092abe5d@65.21.250.197:46656,9cb73281f6774e42176905e548c134fc45bbe579@162.55.134.54:26656,27b07238cf2ea76acabd5d84d396d447d72aa01b@65.109.54.15:51656,f10c2cb08f82225a7ef2367709e8ac427d61d1b5@57.128.144.247:26656,20b4f9207cdc9d0310399f848f057621f7251846@222.106.187.13:40006,5019864f233cee00f3a6974d9ccaac65caa83807@162.19.31.150:55256,2144ce0e9e08b2a30c132fbde52101b753df788d@194.163.168.99:26656,b37326e3acd60d4e0ea2e3223d00633605fb4f79@nebula.p2p.org:26656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.neutrond/config/config.toml

# other configs
sed -i 's|^timeout_commit *=.*|timeout_commit = "2s"|' $HOME/.neutrond/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.neutrond/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.neutrond/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.neutrond/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/neutrond.service > /dev/null << EOF
[Unit]
Description=Neutron Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which neutrond) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

neutrond tendermint unsafe-reset-all --home $HOME/.neutrond --keep-addr-book

SNAP_RPC="https://neutron-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.neutrond/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable neutrond
sudo systemctl start neutrond

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
