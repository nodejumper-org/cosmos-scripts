#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="jackal-1"
CHAIN_DENOM="ujkl"
BINARY="canined"
CHEAT_SHEET="https://nodejumper.io/jackal-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf canine-chain
git clone https://github.com/JackalLabs/canine-chain.git
cd canine-chain || return
git checkout v1.1.2-hotfix
make install
canined version # 1.1.2

canined config keyring-backend test
canined config chain-id $CHAIN_ID
canined init $NODE_MONIKER --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/JackalLabs/canine-mainnet-genesis/main/genesis/genesis.json > $HOME/.canine/config/genesis.json
sha256sum $HOME/.canine/config/genesis.json # 851717cefe35004661fea8ff35212f35277f48c88ea0828b1ef6e877e5b4c787

curl -s https://snapshots2.nodejumper.io/jackal/addrbook.json > $HOME/.canine/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.025ujkl"|g' $HOME/.canine/config/app.toml
seeds=""
peers="b8b29fe5391749ca1425e60212a944e24ac4a03e@jackal.nodejumper.io:31656,a79da224ad9d4501dbf1d547986ebec55d56b951@135.181.128.114:17556,dd7e72f0a71476e51c0a601a40d6fc02a1ae1a95@65.108.6.45:60856,dbbd1e102b9d0cde827cd272205fa3a2886a6b2c@5.9.147.22:21656,8314357f705b8ff9338d58f47fbea99294319cad@57.128.65.115:14656,9bcaee1ad957fa75f60a6dd9d8870e53220794a9@104.37.187.214:60756,dbec14a10d43c25d77ee9987a985652fa4e6344a@131.153.59.6:26656,a2afb42b65da7013eca54778ce01dfb877c2a82a@154.12.227.132:37656,0faa7f1099de2e02deebe09fcb52863056333265@144.202.72.17:26616,7574e0ab179fc6cc47ac89284f4641790218540e@18.163.165.245:26626,ee2ef67b49cbc7b4af7ff0b7321870a5d9ae69a5@65.108.138.80:17556"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.canine/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.canine/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.canine/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.canine/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/canined.service > /dev/null << EOF
[Unit]
Description=Jackal Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which canined) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

canined tendermint unsafe-reset-all --home $HOME/.canine --keep-addr-book

SNAP_RPC="https://jackal.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.canine/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable canined
sudo systemctl restart canined

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"