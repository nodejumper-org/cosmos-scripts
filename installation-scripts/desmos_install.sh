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

cd && rm -rf desmos && rm -rf .desmos
git clone https://github.com/desmos-labs/desmos.git
cd desmos && git checkout tags/v2.3.1 && make install

desmos version # 2.3.1

# replace nodejumper with your own moniker, if you'd like
desmos init "${1:-nodejumper}" --chain-id desmos-mainnet

cd && wget https://raw.githubusercontent.com/desmos-labs/mainnet/main/genesis.json
mv -f genesis.json ~/.desmos/config/genesis.json
jq -S -c -M '' ~/.desmos/config/genesis.json | shasum -a 256 # 619c9462ccd9045522300c5ce9e7f4662cac096eed02ef0535cca2a6826074c4  -

sed -i 's/^minimum-gas-prices *=.*/minimum-gas-prices = "0.0001udsm"/g' ~/.desmos/config/app.toml
seeds="9bde6ab4e0e00f721cc3f5b4b35f3a0e8979fab5@seed-1.mainnet.desmos.network:26656,5c86915026093f9a2f81e5910107cf14676b48fc@seed-2.mainnet.desmos.network:26656,45105c7241068904bdf5a32c86ee45979794637f@seed-3.mainnet.desmos.network:26656"
peers="f090ead239426219d605b392314bdd73d16a795f@rpc1.nodejumper.io:32656"
sed -i -e "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.desmos/config/config.toml

# in case of pruning
sed -i 's/pruning = "default"/pruning = "custom"/g' ~/.desmos/config/app.toml
sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' ~/.desmos/config/app.toml
sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' ~/.desmos/config/app.toml

sudo tee /etc/systemd/system/desmosd.service > /dev/null << EOF
[Unit]
Description=Desmos Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which desmos) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

desmos unsafe-reset-all

SNAP_RPC="http://rpc1.nodejumper.io:32657"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" ~/.desmos/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable desmosd
sudo systemctl restart desmosd
