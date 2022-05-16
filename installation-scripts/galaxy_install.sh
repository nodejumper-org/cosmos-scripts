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

sudo apt install -y make gcc jq git

cd && rm -rf galaxy && rm -rf .galaxy
cd && git clone https://github.com/galaxies-labs/galaxy
cd galaxy && git checkout v1.0.0 && make install

galaxyd version # launch-gentxs

# replace nodejumper with your own moniker, if you'd like
galaxyd config chain-id galaxy-1
galaxyd init "${1:-nodejumper}" --chain-id galaxy-1

cd && wget https://media.githubusercontent.com/media/galaxies-labs/networks/main/galaxy-1/genesis.json
mv -f genesis.json ~/.galaxy/config/genesis.json
sha256sum ~/.galaxy/config/genesis.json # 2003cfaca53c3f9120a36957103fbbe6562d4f6c6c50a3e9502c49dbb8e2ba5b

sed -i 's/^minimum-gas-prices *=.*/minimum-gas-prices = "0.0001uglx"/g' ~/.galaxy/config/app.toml
seeds=""
peers="1e9aa80732182fd7ea005fc138b05e361b9c040d@135.181.139.115:30656"
sed -i -e "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.galaxy/config/config.toml

# in case of pruning
sed -i 's/pruning = "default"/pruning = "custom"/g' ~/.galaxy/config/app.toml
sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' ~/.galaxy/config/app.toml
sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' ~/.galaxy/config/app.toml

sudo tee <<EOF >/dev/null /etc/systemd/system/galaxyd.service
[Unit]
Description=Galaxy Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which galaxyd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

galaxyd unsafe-reset-all

SNAP_RPC="http://rpc2.nodejumper.io:30657"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" ~/.galaxy/config/config.toml

sudo systemctl daemon-reload && sudo systemctl enable galaxyd \
&& sudo systemctl restart galaxyd && sudo journalctl -u galaxyd -f --no-hostname -o cat
