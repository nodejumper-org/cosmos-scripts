#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

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

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf sei-chain
git clone https://github.com/sei-protocol/sei-chain.git
cd sei-chain || return
git checkout 1.1.1beta
make install
seid version

seid config keyring-backend test
seid config chain-id $CHAIN_ID
seid init $NODE_MONIKER --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/sei-protocol/testnet/main/sei-incentivized-testnet/genesis.json > $HOME/.sei/config/genesis.json
sha256sum $HOME/.sei/config/genesis.json # 4ae7193446b53d78bb77cab1693a6ddf6c1fe58c9693ed151e71f43956fdb3f7

curl -s https://raw.githubusercontent.com/sei-protocol/testnet/main/sei-incentivized-testnet/addrbook.json > $HOME/.sei/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001usei"|g' $HOME/.sei/config/app.toml
seeds="df1f6617ff5acdc85d9daa890300a57a9d956e5e@sei-atlantic-1.seed.rhinostake.com:16660"
peers="4b5fb7390e9c64bc96f048816f472f4559fafd94@sei-testnet.nodejumper.io:28656,4b5fb7390e9c64bc96f048816f472f4559fafd94@sei-testnet.nodejumper.io:28656,45b4b8ddb11e575ae11ae80da172e2d030b64479@95.217.12.131:26656,8bd7bd4cfce28f5226f422fd85845e949cf6dfd0@65.108.246.4:26656,3d9f0098ca688b92bb21aed423d131dd7facaad7@217.79.178.14:26656,edb62e1f56ebea162fbfa6d61bff8c954eefd26c@167.235.58.116:26656,b394718cacbcb13337b6903905554535154169e6@176.126.87.128:26656,8e05189591bc3a6b9cb636daf05fee7ff47e975a@64.227.40.51:26656,994e38eaf5eb6021fa0064161696fc9ffd955259@89.163.208.177:26656,aaa1da62895d2a8daaf09b235ca82a55c8d9efd7@173.212.203.238:46656,577737740332cdcef7d02c63eade18211f583558@149.102.133.116:12656,bd9641a334d6d10b5fdb55b623bab103be8ba5ff@185.231.154.243:26656,5c1ef680038d1a357b4c105fdce9e80a9553af98@149.102.138.181:26656,e772c28c8f0a36cbadc48438ab6b950f262519d4@77.37.176.99:26656,dd79c1b2ca0667505c581d62f80d5a94b1e30097@157.245.100.103:36376,ad6d30dc6805df4f48b49d9013bbb921a5713fa6@20.211.82.153:26656,ff9305a6acfaf206dbf4ee2c6e732875c59b608b@149.102.140.38:12656,62744edab552772612c150faa22929c7ad7cc4df@38.242.148.172:26656,3b5ae3a1691d4ed24e67d7fe1499bc081c3ad8b0@65.108.131.189:20956,15139786b29d53366209748f425ee42ae3e9aef0@194.163.132.127:26656,02be57dc6d6491bf272b823afb81f24d61243e1e@141.94.139.233:26656,873a358b46b07c0c7c0280397a5ad27954a10633@141.95.175.196:26656,16225e262a0d38fe73073ab199f583e4a607e471@135.181.59.162:19656,8d30215eb6947e36ffe572ea9b48409492c03494@168.119.149.188:26656"
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
