#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="reb_3333-1"
CHAIN_DENOM="arebus"
BINARY="rebusd"
CHEAT_SHEET="https://nodejumper.io/rebus-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf rebus.core
git clone https://github.com/rebuschain/rebus.core.git
cd rebus.core || return
git checkout testnet
make install
rebusd version # testnet.6f73acac323e89b6b1f7b38aa1ee884b39234e75

rebusd config keyring-backend test
rebusd config chain-id $CHAIN_ID
rebusd init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/rebuschain/rebus.testnet/master/rebus_3333-1/genesis.json > $HOME/.rebusd/config/genesis.json
sha256sum $HOME/.rebusd/config/genesis.json # d382339b5187693ef2e57ff4f33c571ee9bb238ce9fcd68ca99c02116576c41b

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001arebus"|g' $HOME/.rebusd/config/app.toml
seeds="a6d710cd9baac9e95a55525d548850c91f140cd9@3.211.101.169:26656,c296ee829f137cfe020ff293b6fc7d7c3f5eeead@54.157.52.47:26656"
peers="cfaaa1aa3b47a3d457bd7bad4ca54a18829b83cc@rebus-testnet.nodejumper.io:29656,1ae3fe91ec7aba98eba3aa472453a92aa0a38c04@116.202.169.22:28656,289b378944a9983dc7f6ed6b09ba4a30d8290ee1@148.251.53.155:28656,f2cf370ecff71c0e95b0970f3b2821ea11b66a40@195.201.165.123:20106,1f40e130d2c21a32b0d678eabddc45ec3d6964a2@138.201.127.91:26674,82fc54cd4f7cbb44ee5e9d0565d40b5b29475974@88.198.242.163:46656,bdb21276daf5cc3672ddf5597c68c61dc44ec8e5@212.154.90.211:21656,bcf1b8d1896031da70f5bd1d634d10591d066b1c@5.161.128.219:28656,8abcf4cbdfa413f310e792f31aa54e82e9e09a0c@38.242.131.51:26656,eb47d2414351c010c8f747701f184cf3f8a30181@79.143.179.196:16656,f084e8960bb714c3446796cb4738e78bc5c3f04b@65.109.18.179:31656,34dde0a9cac6aeecc3e6570b59a0d297ab64f5bd@65.108.126.46:31656,d5c87b9a13a3d5be1456e9d982c1fc0fe71d8723@38.242.156.72:26656,d4ac8ea1bc083d6348997fda833ffcf5b150bd92@38.242.156.132:26656,d1a72df36686394e99ff0fff006d58f042692699@161.97.136.177:21656,c2368a4db640aa26fb8d5bc9d0f331758d42ca86@141.95.65.26:28656,9f601f082beb325abf3b6b08cdf27374c8a29469@38.242.206.198:56656,64f998cfa053619f1c755fdb6b7e431ae7c0c7b3@95.217.89.23:30530"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.rebusd/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.rebusd/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.rebusd/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.rebusd/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.rebusd/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/rebusd.service > /dev/null << EOF
[Unit]
Description=Rebus Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which rebusd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

rebusd tendermint unsafe-reset-all --home $HOME/.rebusd --keep-addr-book

SNAP_RPC="https://rebus-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.rebusd/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable rebusd
sudo systemctl restart rebusd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
