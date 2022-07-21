#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="teritori-testnet-v2"
CHAIN_DENOM="utori"
BINARY="teritorid"
CHEAT_SHEET="https://nodejumper.io/teritori-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf anone
git clone https://github.com/TERITORI/teritori-chain
cd teritori-chain || return
git checkout teritori-testnet-v2
make install
teritorid version # teritori-testnet-v2-0f4e5cb1d529fa18971664891a9e8e4c114456c6

teritorid config chain-id $CHAIN_ID
teritorid init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/TERITORI/teritori-chain/main/testnet/teritori-testnet-v2/genesis.json > $HOME/.teritorid/config/genesis.json
sha256sum $HOME/.teritorid/config/genesis.json # 2f1dbf5cc8b302dbbea2e2d14598d77d59a49d70743375d3bab6abea1889fde0

seeds=""
peers="0d19829b0dd1fc324cfde1f7bc15860c896b7ac1@teritori-testnet.nodejumper.io:27656,87fd0780bac408fe94ca7b2d9cb82fbef599af41@65.108.52.192:46656,4217ea4193bb066d28825562685c851b3e341369@65.109.10.154:26656,f0521297463bfab11cf29205511788de33efbf0c@162.55.165.168:26656,d737f16ad665889ca800d870bf10d2d478df1fe4@195.54.41.122:26656,5c52667ed7bda88604b8f2357ce37e9f26569e99@78.46.106.75:26656,8693c93371a7e1766225d377f09dcea7177007ee@185.194.218.196:36656,34df38933c32ee21078c1d79787d76668f398b9e@89.163.231.30:36656,545b1fe982b92aeb9f1eadd05ab0954b38eba402@194.163.177.240:26656,0248e2989a8a4f6ad87cbe0490c08908a2c2da7f@5.199.133.165:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.teritorid/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.teritorid/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.teritorid/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.teritorid/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/teritorid.service > /dev/null << EOF
[Unit]
Description=Teritori Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which teritorid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

teritorid tendermint unsafe-reset-all --home $HOME/.teritorid --keep-addr-book

SNAP_RPC="https://teritori-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.teritorid/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable teritorid
sudo systemctl restart teritorid

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
