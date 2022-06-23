#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)

sudo apt update
sudo apt install -y make gcc jq curl git snapd
sudo snap install lz4

if [ ! -f "/usr/local/go/bin/go" ]; then
  . <(curl -s "https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/go_install.sh")
  . .bash_profile
fi
go version # go version goX.XX.X linux/amd64

cd || return
git clone https://github.com/ingenuity-build/quicksilver.git
cd quicksilver || return
git checkout v0.4.0
make install
quicksilverd version # v0.4.0

# replace nodejumper with your own moniker, if you'd like
quicksilverd config chain-id killerqueen-1
quicksilverd init "${1:-nodejumper}" --chain-id killerqueen-1

curl https://raw.githubusercontent.com/ingenuity-build/testnets/main/killerqueen/genesis.json > $HOME/.quicksilverd/config/genesis.json
sha256sum $HOME/.quicksilverd/config/genesis.json # 3510dd3310e3a127507a513b3e9c8b24147f549bac013a5130df4b704f1bac75

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uqck"|g' $HOME/.quicksilverd/config/app.toml
seeds="dd3460ec11f78b4a7c4336f22a356fe00805ab64@seed.killerqueen-1.quicksilver.zone:26656,8603d0778bfe0a8d2f8eaa860dcdc5eb85b55982@seed02.killerqueen-1.quicksilver.zone:27676"
peers="c5cbd164de9c20a13e54e949b63bcae4052a948c@138.201.139.175:20956,9428068507466b542cbf378d59b77746c1d19a34@157.90.35.151:26657,4e7a6d8a3c8eeaad4be4898d8ec3af1cef92e28d@93.186.200.248:26656,eaeb462547cf76c3588e458120097b51db732b14@194.163.155.84:26656,51af5b6b4b0f5b2b53df98ec1b029743973f08aa@75.119.145.20:26656,9a9ed14d71a88354b0383419432ecce70e8cd2b3@161.97.152.215:26656,43bca26cb1b2e7474a8ffa560f210494023d5de4@135.181.140.225:26657,1ba34e984db33e075f10b4139a514e9ff7c07d7d@65.21.131.215:26676,86b0be64be9637f6e23ecf475edd164fa07b5665@65.21.134.202:26676,quickvaloper1k5z844rctd8jtaw4t22ae2308h4pew0ups676v"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.quicksilverd/config/config.toml
sed -i 's|^indexer *=.*|indexer = "null"|g' $HOME/.quicksilverd/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.quicksilverd/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.quicksilverd/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.quicksilverd/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.quicksilverd/config/app.toml

sudo tee /etc/systemd/system/quicksilverd.service > /dev/null << EOF
[Unit]
Description=Quicksilver Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which quicksilverd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

quicksilverd tendermint unsafe-reset-all --home $HOME/.quicksilverd --keep-addr-book

SNAP_RPC="http://rpc1-testnet.nodejumper.io:31657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.quicksilverd/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable quicksilverd
sudo systemctl restart quicksilverd
