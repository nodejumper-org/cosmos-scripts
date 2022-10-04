#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="teritori-1"
CHAIN_DENOM="utori"
BINARY="teritorid"
CHEAT_SHEET="https://nodejumper.io/teritori/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf teritori-chain
git clone https://github.com/TERITORI/teritori-chain
cd teritori-chain || return
git checkout v1.1.2
make install
teritorid version # v1.1.2

teritorid config chain-id $CHAIN_ID
teritorid init $NODE_MONIKER --chain-id $CHAIN_ID

curl -L -s https://github.com/TERITORI/teritori-mainnet-genesis/blob/main/genesis.json?raw=true > $HOME/.teritorid/config/genesis.json
sha256sum $HOME/.teritorid/config/genesis.json #daa42b259c5db6a602cb8cf0691a866839494b9ed550c529665fdc857bd68d43

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001utori"|g' $HOME/.teritorid/config/app.toml
seeds=""
peers="26175f13ada3d61c93bca342819fd5dc797bced0@teritori.nodejumper.io:28656,8f4db549de62fbb96cf4cf477e2af9c52f74a3dd@51.91.64.170:19656,061002c13cbd007c7093d331cf7cf679de1a60f2@65.108.248.127:60556,7a4e9803857452692f9eb4ac8975ea25a52a9a37@167.235.36.159:32656,787a6b318ebc4167fefb1d5ef9f88af6cb5a8b29@173.212.222.167:35656,d817cef328f31e197a55d8954b589e23e365d868@194.163.190.91:19656,a0ee08226a651d9fae4a0b04be370542e748b508@5.161.102.137:26656,d9a15c3e8d19b573ba4ddd834c2f20ec13c1643d@161.97.69.121:26656,0212e8a654e6157f7e1332d0a399b27d02843bdd@65.108.0.93:46656,526d8c7c44f59be9a39d7463c576b68c0db23174@65.108.234.23:15956,2b4f46e601fb4ede2a0c98976337e3afdaa50dac@65.108.238.102:15956,8ac41af54dfd91c41de71cde222a55670f2f405d@141.95.65.73:15956,9557321c379768c1a3d39d71e6dc9cdaf0dd561e@116.202.143.91:26656,09a170f92617ce476f6c8f17e4a8a7e5c3405388@161.97.150.231:26656,6fd88e2143e6d4ba02a7f745565120df18e84699@109.236.80.46:26656,82ebb17ddac20928fb8107201dad9f5aea7f9132@198.244.200.3:26656,2da1141f27d403e9d0cd0ecf3f02d71a3ed5031a@[2001:41d0:2:a89b::1]:30553,3594b73f909a9c4b87cfe6a361ef8b2b51124dd5@65.109.69.59:15956,e227a6949aadb627957c00f004ff16c001503c00@5.9.147.185:16656,e865b4c1ba3950d44284a7e7dd97f0e852618ac3@185.234.247.166:26656,a6d2c4de332606a98915e98e6a2d042779464680@161.97.155.94:26656,ab03f6d2d469e0be5b7fd5cb7388c7feffc1deac@15.235.114.194:10656,7f9773971291b77b2d65364a8928cb31c40aa70f@65.108.73.124:13656,49ac240331bf10f6a0e39969d9b2e8d624b15445@135.181.88.15:19656,647bbbc30d26fbbb2f7d19aafe30ed77a92c4748@[2a01:4f9:6b:2e5b::4]:26656,7fbfea037bd7962199ffbfd25986c014bab05298@65.108.140.17:32656,1f858b8cc8e18ef05de79dd470ad29ba29ddbeb7@65.108.77.106:26889,ad95a806c87682a553725a76329646425607d79f@65.108.105.25:10856,24b28cf013e6d7b5b88b6dba2701c5ddd2dd5ee1@65.109.58.225:28656,5ab6437f73fe71f392d53566e037aa91087530ac@139.144.67.202:26656"
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

cd "$HOME/.teritorid" || return
rm -rf data

SNAP_NAME=$(curl -s https://snapshots3.nodejumper.io/teritori/ | egrep -o ">teritori-1.*\.tar.lz4" | tr -d ">")
curl https://snapshots3.nodejumper.io/teritori/${SNAP_NAME} | lz4 -dc - | tar -xf -

sudo systemctl daemon-reload
sudo systemctl enable teritorid
sudo systemctl restart teritorid

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
