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

cd && rm -rf rizon && rm -rf .rizon
git clone https://github.com/rizon-world/rizon.git
cd rizon && git checkout v0.3.0 && make install

rizond version # v0.3.0

# replace nodejumper with your own moniker, if you'd like
rizond init "${1:-nodejumper}" --chain-id titan-1

cd && wget https://raw.githubusercontent.com/rizon-world/mainnet/master/genesis.json
mv -f genesis.json ~/.rizon/config/genesis.json
jq -S -c -M '' ~/.rizon/config/genesis.json | shasum -a 256 # 5f00af49e86f5388203b8681f4482673e96acf028a449c0894aa08b69ef58bcb  -

sed -i 's/^minimum-gas-prices *=.*/minimum-gas-prices = "0.0001uatolo"/g' ~/.rizon/config/app.toml
seeds="83c9cdc2db2b4eff4acc9cd7d664ad5ae6191080@seed-1.mainnet.rizon.world:26656,ae1476777536e2be26507c4fbcf86b67540adb64@seed-2.mainnet.rizon.world:26656,8abf316257a264dc8744dee6be4981cfbbcaf4e4@seed-3.mainnet.rizon.world:26656"
peers="0d51e8b9eb24f412dffc855c7bd854a8ecb3dff5@rpc1.nodejumper.io:26656,422f0d89944ab2661c0fafe05c84302260fff94e@rpc2.nodejumper.io:26656"
sed -i.bak -e "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.rizon/config/config.toml

# in case of pruning
sed -i 's/pruning = "default"/pruning = "custom"/g' ~/.rizon/config/app.toml
sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' ~/.rizon/config/app.toml
sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' ~/.rizon/config/app.toml

sudo tee <<EOF >/dev/null /etc/systemd/system/rizond.service
[Unit]
Description=Rizon Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which rizond) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

rizond unsafe-reset-all

SNAP_RPC="http://rpc1.nodejumper.io:26657"
SNAP_RPC2="http://rpc2.nodejumper.io:26657"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC2\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" ~/.rizon/config/config.toml

sudo systemctl daemon-reload && sudo systemctl enable rizond \
&& sudo systemctl restart rizond && sudo journalctl -u rizond -f --no-hostname -o cat
