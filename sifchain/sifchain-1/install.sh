#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="sifchain-1"
CHAIN_DENOM="rowan"
BINARY="sifnoded"
CHEAT_SHEET="https://nodejumper.io/sifchain/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf sifnode
git clone https://github.com/Sifchain/sifnode.git
cd sifnode || return
git checkout v1.0-beta.12-issuefix
make install
sifnoded version # v1.0-beta.12-issuefix

sifnoded init $NODE_MONIKER --chain-id $CHAIN_ID
sed -i 's|^chain-id *=.*|chain-id = "'$CHAIN_ID'"|g' $HOME/.sifnoded/config/client.toml

curl https://raw.githubusercontent.com/Sifchain/networks/master/betanet/sifchain-1/genesis.json.gz > ~/.sifnoded/config/genesis.zip
gunzip -c ~/.sifnoded/config/genesis.zip > ~/.sifnoded/config/genesis.json
rm -rf ~/.sifnoded/config/genesis.zip
sha256sum $HOME/.sifnoded/config/genesis.json # b534aac6334611c2209f12f60a22dd86ec38151704d00063dc2243184fa53887

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001rowan"|g' $HOME/.sifnoded/config/app.toml
seeds=""
peers="6409c82fc0ff91c5016cafab71cf6c95aae1e36d@sifchain.nodejumper.io:27656,27a556e6b66a821d26f9e0bfed8ed6d1c2c4f394@65.109.58.225:27656,3d10d430772df00bb9718035ec3cdd59a92a5374@65.109.22.187:26656,873fb0a00d94d8b23dd37cadd98233a59e49e38c@161.97.156.216:30656,4a0099b47580cfbc5c8f7df9ab68559b433af5bd@5.9.137.186:26656,0b2674574624c1cf5c085d682afcace2ccc9f11c@5.9.137.98:26656,e72228cb0b6591e529cccb16019a70ca013a8387@78.46.75.70:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.sifnoded/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.sifnoded/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.sifnoded/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.sifnoded/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/sifnoded.service > /dev/null << EOF
[Unit]
Description=Sifchain Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which sifnoded) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

sifnoded tendermint unsafe-reset-all --home $HOME/.sifnoded --keep-addr-book

SNAP_RPC="https://sifchain.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.sifnoded/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable sifnoded
sudo systemctl restart sifnoded

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
