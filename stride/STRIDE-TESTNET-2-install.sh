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
git checkout 4ec1b0ca818561cef04f8e6df84069b14399590e
make build
mkdir -p $HOME/go/bin
sudo cp $HOME/stride/build/strided $HOME/go/bin
strided version #v0.3.1

strided config chain-id $CHAIN_ID
strided init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/Stride-Labs/testnet/main/poolparty/genesis.json > $HOME/.stride/config/genesis.json
sha256sum $HOME/.stride/config/genesis.json # d6204cd1e90e74bb29e9e0637010829738fa5765869288aa29a12ed83e2847ea

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ustrd"|g' $HOME/.stride/config/app.toml
seeds="c0b278cbfb15674e1949e7e5ae51627cb2a2d0a9@seedv2.poolparty.stridenet.co:26656"
peers="17b24705533d633cb3501233a18912ae6cc36a41@stride-testnet.nodejumper.io:28656,48b1310bc81deea3eb44173c5c26873c23565d33@stride-testnet-2-node1.poolparty.stridenet.co:26656,17b24705533d633cb3501233a18912ae6cc36a41@stride-testnet.nodejumper.io:28656,fe32bb1711c38fd5af5ec9ae9db50c694c872194@23.88.77.188:20005,04ef750b843220e6aa93a1b097a4e51e5257a910@135.181.19.231:36656,57e3541c58441e2f6f955eb67b125b09a96086ac@65.21.131.215:26616,d5a52e246601ea09f4543e43aab65fea113ce080@65.108.101.50:60556,a4c25f4b10e33c72749861ed9e142e2986aaaeec@213.239.218.210:26656,8c069ced6c1689c5680efa8f9b26df20b83bcd4d@141.147.7.244:16656,fef5a04c72fb967e4271d0d73cfa8a87234b0dd3@95.217.155.89:16656,b96c807bfcab89fbf50c1d333701bd7ef255f7d6@65.108.58.240:16656,6ccb1b48b804571738abd1c5b376e5fcddc9a1e5@194.163.162.179:26656,c283ee6d2753e432f1103677b9db98a5a66356f6@146.190.26.115:16656,43dac7973942595885bb7930382e4514be19504b@31.187.74.204:16656,469d045599d0812a8a3b1e3e36358b7f8e4e2d53@95.216.218.102:26656"
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
