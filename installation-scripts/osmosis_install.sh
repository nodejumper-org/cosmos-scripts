sudo apt update && sudo apt upgrade -y

version="1.17.2" \
&& cd ~ \
&& wget "https://golang.org/dl/go$version.linux-amd64.tar.gz" \
&& sudo rm -rf /usr/local/go \
&& sudo tar -C /usr/local -xzf "go$version.linux-amd64.tar.gz" \
&& rm "go$version.linux-amd64.tar.gz" \
&& echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile \
&& source ~/.bash_profile

go version # go version go1.17.2 linux/amd64

sudo apt install -y make gcc jq

cd && git clone https://github.com/osmosis-labs/osmosis
cd osmosis && git checkout v7.0.3 && make install

osmosisd version # 7.0.3

# replace nodejumper with your own moniker, if you'd like
osmosisd init "${1:-nodejumper}" --chain-id osmosis-1

cd && wget https://github.com/osmosis-labs/networks/raw/main/osmosis-1/genesis.json
mv -f genesis.json ~/.osmosisd/config/genesis.json
jq -S -c -M '' ~/.osmosisd/config/genesis.json | shasum -a 256 # 23fe76392e7535eafb73f6d60f08538b2f35272454b4598b734b4ecb6f5a7c5e  -

sed -i 's/^minimum-gas-prices *=.*/minimum-gas-prices = "0.0001uosmo"/g' ~/.osmosisd/config/app.toml
seeds=""
peers="83c06bc290b6dffe05aa9cec720bedfc118afcbc@rpc2.nodejumper.io:35656"
sed -i -e "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.osmosisd/config/config.toml

# in case of pruning
sed -i 's/pruning = "default"/pruning = "custom"/g' ~/.osmosisd/config/app.toml
sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' ~/.osmosisd/config/app.toml
sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' ~/.osmosisd/config/app.toml

sudo tee <<EOF >/dev/null /etc/systemd/system/osmosisd.service
[Unit]
Description=Osmosis Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which osmosisd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

osmosisd unsafe-reset-all

SNAP_RPC="http://rpc2.nodejumper.io:35657"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" ~/.osmosisd/config/config.toml

sudo systemctl daemon-reload && sudo systemctl enable osmosisd \
&& sudo systemctl restart osmosisd && sudo journalctl -u osmosisd -f --no-hostname -o cat