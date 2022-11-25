#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="reb_1111-1"
CHAIN_DENOM="arebus"
BINARY="rebusd"
CHEAT_SHEET="https://nodejumper.io/rebus/cheat-sheet"

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
git checkout v0.2.0
make install
rebusd version # HEAD.f3cd9873b77d6a40738b187572249d715a75bbd4

rebusd config chain-id $CHAIN_ID
rebusd init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/rebuschain/rebus.mainnet/master/reb_1111-1/genesis.zip > ~/.rebusd/config/genesis.zip
rm -rf ~/.rebusd/config/genesis.json
unzip ~/.rebusd/config/genesis.zip -d ~/.rebusd/config
sha256sum $HOME/.rebusd/config/genesis.json # 10cc853d7ccc8ebc67155ee4ffc1bb32caac3f05873df79e866524898b3f20eb

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001arebus"|g' $HOME/.rebusd/config/app.toml
seeds="e056318da91e77585f496333040e00e12f6941d1@51.83.97.166:26656"
peers="b574e11e103058a121cc03d1c4d9867ba3daed34@rebus.nodejumper.io:31656,ff2657d49f9f50412987a66785e928d7ec9c2f99@88.208.57.200:36656,c56c8b544c99466c1cab6d635da4773e3ebbb510@185.173.157.71:26656,237bfc05da5f8cabee00f148995333f37186d232@164.68.121.101:26656,87102b5dd22c1d17f97197c078f23726ae3c6214@91.157.60.253:26656,94b63fddfc78230f51aeb7ac34b9fb86bd042a77@[2a01:4f9:4a:196f::2]:30543,89ded0a3987d22e46b756fead439e2a4d25f23cb@185.144.99.30:26656,4ef77b2a17e71d2535b3c8ec11830708fc299705@209.222.98.90:26656,f83df63886e56713bf3adb5c6836b1a7b07ec024@65.108.235.18:26656,a155d381099de93e7efe00f9475786abffd29c3e@167.235.29.125:26637,b8c42fcb311b47cdb8285b5697f661fbba5bf1a5@51.68.157.129:26656,b1dcbb37514fbe215be54079e71aa39dac7fd0ae@64.5.123.203:26656,5882961bd31831bf912c0d5fe5486da100c75d6b@65.109.54.110:36656,c88a9a3d3a41a164f8c1537514665e77ea0b54ac@[2a01:4f9:6b:2e5b::9]:26656,7ee74ea68e350fc5214657255cba5e339bb30c2a@138.201.127.91:26674,f5ceadfe92dc08bb57a30977409c8b195b822dc7@194.34.232.124:26656,e9fa8c32e4504013c37d04671a8882c9bfbc47a9@38.242.139.248:26656,07b84cf4b47a2e5ad251267716fe05bcf30330cd@65.21.170.3:29656,1bdbfe0a91638d467dc4915da813e3016410c2d2@176.9.10.239:26656,ea5e7a6b9a5c18c6455e7a8c583c129c5821a452@51.178.80.111:26656,b4941d0929595b9f83d190559e1d7126fec91cb0@172.96.161.94:26656,7197d316935ca7b7ac36da7d4a3a6df16cd286a7@93.170.72.118:26656,5fb9952f3eaeb5be3aab37425831c2a4830a019d@65.21.133.125:29656,d28516746773bfaeca4efa5537c0bf5990b8828e@65.21.229.33:27656,3a3e7123b9ae814b8d8517b6635d21b9ae45bf25@195.3.222.148:26656,64ab3b0223ac85513b14617525efbb4ebb08f79f@65.109.25.49:26656,a7dd6ba407b4567372073f0c675dc0fa9703929e@141.95.124.152:20106,dda7abe32cc84a722cf6b1d2ee3b61ebe7ad71df@135.181.212.183:21656,eeca453e3a1cf670c78e2255b8f0bd5a9443c30b@65.108.225.71:26656"
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

SNAP_RPC="https://rebus.nodejumper.io:443"
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
