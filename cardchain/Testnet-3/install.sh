#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="Testnet3"
CHAIN_DENOM="ubpf"
BINARY="Cardchaind"
CHEAT_SHEET="https://nodejumper.io/cardchain-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

curl -L https://github.com/DecentralCardGame/Cardchain/releases/download/v0.81/Cardchain_latest_linux_amd64.tar.gz > Cardchain_latest_linux_amd64.tar.gz
tar xzf Cardchain_latest_linux_amd64.tar.gz
chmod 775 +x Cardchaind
sudo mv Cardchaind /usr/local/bin/
rm Cardchain_latest_linux_amd64.tar.gz

Cardchain config keyring-backend test
Cardchain config chain-id $CHAIN_ID
Cardchain init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/DecentralCardGame/Testnet/main/genesis.json > $HOME/.Cardchain/config/genesis.json
sha256sum $HOME/.Cardchain/config/genesis.json # 4f189f5eb4cf7815f205a5df17e3a2365035e68cc7ce03adce4e1733e3e07822

seeds=""
peers="c33a6ea0c7f82b4cc99f6f62a0e7ffdb3046a345@cardchain-testnet.nodejumper.io:30656,56d11635447fa77163f31119945e731c55e256a4@45.136.28.158:26658"
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
ExecStart=$(which Cardchaind) start
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
echo -e "Check logs:            ${CYAN}sudo journalctl -u ${BINARY}d -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
