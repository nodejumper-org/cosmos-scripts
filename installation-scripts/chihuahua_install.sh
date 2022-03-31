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

cd && rm -rf chihuahua && rm -rf .chihuahua
git clone https://github.com/ChihuahuaChain/chihuahua.git
cd chihuahua && git checkout v1.1.1 && make install

chihuahuad version # v1.1.1

# replace nodejumper with your own moniker, if you'd like
chihuahuad init "${1:-nodejumper}" --chain-id chihuahua-1

cd && wget https://raw.githubusercontent.com/ChihuahuaChain/mainnet/main/genesis.json
mv -f genesis.json ~/.chihuahua/config/genesis.json
jq -S -c -M '' ~/.chihuahua/config/genesis.json | shasum -a 256 # 2d0709eeb6610fc41584d2d76ec5c83ba8537dc6615f36c520966eb43dc0b386  -

sed -i 's/^minimum-gas-prices *=.*/minimum-gas-prices = "0.0001uhuahua"/g' ~/.chihuahua/config/app.toml
seeds=""
peers="c9b1385f81bec76dd6a84311de997d1e783dba53@rpc1.nodejumper.io:29656,584ab034cafa8e9229c2b2fa2eda9ab0bb4e399e@rpc2.nodejumper.io:29656"
sed -i.bak -e "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.chihuahua/config/config.toml

# in case of pruning
sed -i 's/pruning = "default"/pruning = "custom"/g' ~/.chihuahua/config/app.toml
sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' ~/.chihuahua/config/app.toml
sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' ~/.chihuahua/config/app.toml

sudo tee <<EOF >/dev/null /etc/systemd/system/chihuahuad.service
[Unit]
Description=Chihuahua Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which chihuahuad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

chihuahuad unsafe-reset-all

SNAP_RPC="http://rpc1.nodejumper.io:29657"
SNAP_RPC2="http://rpc2.nodejumper.io:29657"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC2\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" ~/.chihuahua/config/config.toml

sudo systemctl daemon-reload && sudo systemctl enable chihuahuad \
&& sudo systemctl restart chihuahuad && sudo journalctl -u chihuahuad -f --no-hostname -o cat
