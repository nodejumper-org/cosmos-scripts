#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="atlantic-sub-1"
CHAIN_DENOM="usei"
BINARY="seid"
CHEAT_SHEET="https://nodejumper.io/sei-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf sei-chain
git clone https://github.com/sei-protocol/sei-chain.git
cd sei-chain || return
git checkout tags/1.2.0beta
make install
seid version #1.2.0beta

seid config keyring-backend test
seid config chain-id $CHAIN_ID
seid init $NODE_MONIKER --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/sei-protocol/testnet/main/atlantic-subchains/atlantic-sub-1/genesis.json > $HOME/.sei/config/genesis.json
sha256sum $HOME/.sei/config/genesis.json # b04350f2cc2db7ee1bd6a8a125167ce0a49c528aca78fe95085cdd2413dac863

curl -s https://raw.githubusercontent.com/sei-protocol/testnet/main/atlantic-subchains/atlantic-sub-1/addrbook.json > $HOME/.sei/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001usei"|g' $HOME/.sei/config/app.toml
seeds=""
peers="4b5fb7390e9c64bc96f048816f472f4559fafd94@sei-testnet.nodejumper.io:28656,9042230935e18ddddbf20a0048424dd7d9f933af@135.181.57.209:28056,cb4a8785dcdd2f65bd4c93429779a27e24c87399@65.109.16.162:60556,199fb2a6a411097f2e3fcc15be26be0cfafb1a02@65.108.231.253:36656,e14cb72edc5bf06a55efa7ad1f5b3a5b9a8b167d@65.108.140.222:12656,9324371932afc5a61d048a43c9713ab6742f9ff7@95.216.69.173:26656,76d4edb6049b2c2aa139fb0dcceb1370f830e1a0@95.217.176.153:26656,dd8b73cad778d622c255e6dcebf42262985bae1d@65.21.151.93:36656,7523321221062c5005b447ef562f4ec4553f2f24@95.165.149.94:27656,50f9584a12170db325dce12c1bc81e54f6e45308@89.163.223.34:26656,58a0d3e414f456bfa5efa4c789ce96aaf08a71ca@78.107.234.44:16656,0a08627f8b5e2c3a689ef54f91b237f5bd806a89@77.37.176.99:26656,d4ae3a62044a181cb33124b55c9cee425d66547e@5.161.64.169:26656,1fea05a3023c02c553ddc543a3cd21d142666863@149.102.142.149:26656,02be57dc6d6491bf272b823afb81f24d61243e1e@95.217.229.70:27656,f4b1aa3416073a4493de7889505fc19777326825@135.181.133.37:28656,ca3409b068d2858c4ff2b9543dfbcc0027820816@65.21.138.123:29656,873a358b46b07c0c7c0280397a5ad27954a10633@141.95.104.169:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.sei/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.sei/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.sei/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.sei/config/app.toml

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

sudo systemctl daemon-reload
sudo systemctl enable seid
sudo systemctl restart seid

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
