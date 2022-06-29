#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)

sudo apt update
sudo apt install -y make gcc jq curl git

if [ ! -f "/usr/local/go/bin/go" ]; then
  . <(curl -s "https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/go_install.sh")
  . .bash_profile
fi
go version # go version goX.XX.X linux/amd64

cd || return
rm -rf paloma
mkdir -p $HOME/go/bin
git clone https://github.com/palomachain/paloma.git
cd paloma || return
git checkout v0.2.5-prealpha
go build -o $HOME/go/bin/palomad ./cmd/palomad
sudo curl -s -L https://github.com/CosmWasm/wasmvm/raw/main/api/libwasmvm.x86_64.so -o /usr/lib/libwasmvm.x86_64.so
palomad version # nothing :/

# replace nodejumper with your own moniker, if you'd like
palomad config chain-id paloma-testnet-5
palomad init "${1:-nodejumper}" --chain-id paloma-testnet-5

curl https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-5/genesis.json > $HOME/.paloma/config/genesis.json
curl https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-5/addrbook.json > $HOME/.paloma/config/addrbook.json
sha256sum $HOME/.paloma/config/genesis.json # 922f6ae493fa9a68f88894802ab3a9507dd92b38e090a71e92be42827490ef48


sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ugrain"|g' $HOME/.paloma/config/app.toml
seeds=""
peers="ce2724d2606345049e656fbccabe597af3bccc77@38.242.246.230:26656,bd5570cd42f43cf2695fc6285b55b8b28dfe4edd@38.242.246.224:26656,9fc5c7ff19a4b855b3f662996c95e0e0b14abe25@38.242.246.227:26656,9e6301e23b1661fc59e5cd8a09f11370bcb3404f@38.242.246.231:26656,3ca66c8805dedeea64100bc2ce4c49ac71979e6b@38.242.246.228:26656,41a896277ddf0ee88fa19be93fee62b9ffaa9d28@185.244.181.27:26656,bc8466af250d1e662aa565af47daf833a9629419@159.223.201.45:26656,84e71eff48b4188ef9971c8dadfb9bae2c49e405@152.70.79.67:26656,271d472618e15794a570ec105232910f18ea2de5@188.166.12.124:26656,7edc49e0bf6c6dee827c3a3a6d8df88b612d612d@35.203.66.107:26656,907a6725451d4a890360d91febc049cb78ee0a52@144.91.101.46:36416,f4ca35f06f6abb573bba1c18bfa886f3fde51ae3@80.93.19.96:26656,18da4f4cdc6f3da24138c97e3f0156da4079e20e@65.108.140.101:40656,c792fe6d673360e039c74cd0387884975ddc87da@93.186.200.35:10656,98b112892325872a2ca883afe84d1ad1eb47e13f@154.53.39.182:26656,3bd6035cd2d551a04b2fb897ac362f366acb4b65@45.55.34.66:26656,2af5498ebd7feb5b7b22f51f3649c4c358041c86@128.199.127.179:10656,4e2b1bf7d32da06b42a038d207418f5c9fe16e26@176.126.87.119:26656,6cc4e54bd7a309b4a244ba17aa3d5444a5d2a85a@178.128.51.108:26656,790e895c0ee260b6de66c2b4fa251b4abb7ab5e0@109.238.12.51:26656,a23615206c7f7efc8764164ca75e2b12b9af2031@151.106.8.63:26656,8b56b1d81fa74aeee0423846c4e0e01650dce8e9@137.184.3.67:26656,54aa04dbb56a7ecd50d66abac73c1e61d7928986@38.242.241.167:26656,10c78db5701cbdc30bc4c8ba6f76fd5d5d7df1c5@38.242.212.92:26656,c3fcc1086ec62bbd912cc9fc717f10f24f9df4c6@52.180.137.238:10656,260668797b681c9f099cbe5cbbada9f9e26bcc75@178.18.254.164:26656,fc79567d309705e073fca2e766b93625fa10583a@162.55.234.234:26656,b159364b4e6a3036c36ef6c7c690c5fbc81fa9c4@65.108.71.92:54056,187950523148c1d4c50e215de37d145be48acd15@161.35.234.64:26656,542d60dd2b126b9fee343c52a90fc357556dcd9f@46.228.199.8:26656,b3a183f1cfeec653e3c8507ae9bf7fb7dddc0bdd@144.91.83.185:26656,eb778b77af0c275de975b58902489d1af78d4372@194.163.141.18:26656,8badecc97fefd966267f55337b27be2116274a08@86.32.74.154:26656,f2ccba8389e722f7dfe0c5abefb0f4832f71103f@65.21.146.122:26656,0c0eaabdb333fb5e142d95c389763cb5ba414e47@20.2.83.71:10656,c5d2cb94bea42d4f0189ff55b3eba0199448e5b5@38.242.246.229:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.paloma/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.paloma/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.paloma/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.paloma/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.paloma/config/app.toml

sudo tee /etc/systemd/system/palomad.service > /dev/null << EOF
[Unit]
Description=Paloma Network Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which palomad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

palomad tendermint unsafe-reset-all --home $HOME/.paloma/ --keep-addr-book

SNAP_RPC="http://rpc1-testnet.nodejumper.io:33657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.paloma/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable palomad
sudo systemctl restart palomad
