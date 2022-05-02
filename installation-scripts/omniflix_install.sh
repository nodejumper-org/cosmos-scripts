#!/bin/bash

sudo apt update
sudo apt install -y make gcc jq wget git

if [ ! -f "/usr/local/go/bin/go" ]; then
  version="1.18.1"
  cd && wget "https://golang.org/dl/go$version.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$version.linux-amd64.tar.gz"
  rm "go$version.linux-amd64.tar.gz"
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
  source .bash_profile
fi

go version # go version goX.XX.X linux/amd64

cd && rm -rf omniflixhub && rm -rf .omniflixhub
git clone https://github.com/Omniflix/omniflixhub.git
cd omniflixhub && git checkout v0.4.0 && make install

omniflixhubd version # 0.4.0

# replace nodejumper with your own moniker, if you'd like
omniflixhubd init "${1:-nodejumper}" --chain-id omniflixhub-1

cd && wget https://raw.githubusercontent.com/OmniFlix/mainnet/main/omniflixhub-1/genesis.json
mv -f genesis.json ~/.omniflixhub/config/genesis.json
jq -S -c -M '' ~/.omniflixhub/config/genesis.json | shasum -a 256 # 3c01dd89ae10f3dc247648831ef9e8168afd020946a13055d92a7fe2f50050a0  -

sed -i 's/^minimum-gas-prices *=.*/minimum-gas-prices = "0.0001uflix"/g' ~/.omniflixhub/config/app.toml
seeds="9d75a06ebd3732a041df459849c21b87b2c55cde@35.187.240.195:26656,19feae28207474eb9f168fff9720fd4d418df1ed@35.240.196.102:26656"
peers="b7ac7a52dbb4041133e31e0552f4e01e926d3bb4@rpc2.nodejumper.io:33656"
sed -i -e "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.omniflixhub/config/config.toml

# in case of pruning
sed -i 's/pruning = "default"/pruning = "custom"/g' ~/.omniflixhub/config/app.toml
sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' ~/.omniflixhub/config/app.toml
sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' ~/.omniflixhub/config/app.toml

sudo tee /etc/systemd/system/omniflixhubd.service > /dev/null << EOF
[Unit]
Description=Omniflix Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which omniflixhubd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

omniflixhubd unsafe-reset-all

SNAP_RPC="http://rpc2.nodejumper.io:33657"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" ~/.omniflixhub/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable omniflixhubd
sudo systemctl restart omniflixhubd
