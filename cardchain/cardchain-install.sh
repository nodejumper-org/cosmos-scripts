#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="Cardchain"
CHAIN_DENOM="ubpf"
BINARY="cardchain"
CHEAT_SHEET="https://nodejumper.io/cardchain-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
curl https://get.ignite.com/DecentralCardGame/Cardchain@latest! | sudo bash
Cardchain version # latest-bf2b2b7b

Cardchain config keyring-backend test
Cardchain config chain-id $CHAIN_ID
Cardchain init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/DecentralCardGame/Testnet1/main/genesis.json > $HOME/.Cardchain/config/genesis.json
sha256sum $HOME/.Cardchain/config/genesis.json # 144b5bfb1d63d8787f2300cf50dab6ce1f19524710bc9bc9b51f8d1fd82e517e

seeds=""
peers="c33a6ea0c7f82b4cc99f6f62a0e7ffdb3046a345@cardchain-testnet.nodejumper.io:30656,ebd578ccb7f2e429b6a15864599993deb1c002fa@65.108.231.252:56656,795bfab2ad5186713b32b893630a56d565c828b1@95.217.11.20:26656,12538d158de5712f917581ed3e0716cf56d4e41c@95.217.121.229:26675,45c7f108d747bcfb504171ed0974d2d614be48e2@65.109.17.86:28656,17eb9676dd2757a70056491409d0731a73e8eff3@95.216.223.244:26656,68df6b3b73d38f77b446ba99467c3e87dcaa98a0@65.108.43.9:26656,9b5a5365afcca026cf9ed9c16c2bf37347d3b803@65.109.26.95:26656,420626a99360af55da92026fdaa877d153e48793@45.87.104.113:36656,0626121335c0f5bb06347b219e7fc80d335e30b0@188.120.254.15:26656,754bb98bcc5ed7567ca9a60f71b7a97ede65e21a@88.198.39.43:26756,56ff9898493787bf566c68ede80febb76a45eedc@23.88.77.188:20004,299e8a7cbf8943881160b963a88513609d03f4f8@88.99.70.151:26656,64d47e58d2fd55b6b6e0cfb15334d0a5e2c9acaa@23.88.37.35:26656,7e989e962fa7e246782bcc167bb39ddaa87ed80b@149.102.142.179:26656,e1c58441e7cb70d5919df946a76c5558ccc4976f@194.163.141.216:26656,ef69210fcb08380d73b41b1463b7c7cca96d3b5c@202.61.194.254:60656,f104ffff2d3c8e0efdd9766354274f7c9ceccbb1@173.249.1.210:26656,709be6996af96150acc66b60d8f50857c57cc7f7@167.86.79.177:26656,dd278ef79af97454959346d064cdddb91bba39bb@85.173.112.154:23656,1bd8cbea5eac9642bf22bc151561ac703cbefba3@195.54.41.122:36656,b17b995cf2fcff579a4b4491ca8e05589c2d8627@195.54.41.130:36656,e9fde4104a976d0efcbd1866200b2c5ccf74ec54@154.12.238.226:26656,dc1348cf74908231976fa847ad44933a9cae43ac@207.244.245.125:26656,12a75540cfaae29d15c67bc9cc250abd84badc95@65.108.124.172:30656,c607c5a781bd36805b8898411396f9fabc4eac60@135.181.154.42:26656,652d71612fe2da05f65bf012259c1dc841d89609@65.108.231.253:56656,5968ebe690c1850a5a201675bd79a4aa636f82e3@213.239.217.52:27656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.Cardchain/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.Cardchain/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.Cardchain/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.Cardchain/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/Cardchaind.service > /dev/null << EOF
[Unit]
Description=Cardchain Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which Cardchain) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

Cardchain unsafe-reset-all

SNAP_RPC="https://cardchain-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.Cardchain/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable Cardchaind
sudo systemctl restart Cardchaind

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
