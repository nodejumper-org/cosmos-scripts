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

cd && rm -rf kid && rm -rf .kid
git clone https://github.com/KiFoundation/ki-tools.git
cd ki-tools && git checkout -b v2.0.1 tags/2.0.1 && make install

kid version # Mainnet-IBC-v2.0.1-889c4a2ca6b228247f5cb9366c3c0c894592da27

# replace nodejumper with your own moniker, if you'd like
kid config chain-id kichain-2
kid init "${1:-nodejumper}" --chain-id kichain-2

cd && wget https://raw.githubusercontent.com/KiFoundation/ki-networks/v0.1/Mainnet/kichain-2/genesis.json
mv -f genesis.json ~/.kid/config/genesis.json
jq -S -c -M '' ~/.kid/config/genesis.json | shasum -a 256 # 99855fdf89f5c697f8be2ecc587d79c77259e05d68268928797083bdaa614a80  -

sed -i 's/^minimum-gas-prices *=.*/minimum-gas-prices = "0.0001uxki"/g' ~/.kid/config/app.toml
seeds="24cbccfa8813accd0ebdb09e7cdb54cff2e8fcd9@51.89.166.197:26656"
peers="766ed622c79fa9cfd668db9741a1f72a5751e0cd@rpc1.nodejumper.io:28656"
sed -i -e "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.kid/config/config.toml

# in case of pruning
sed -i 's/pruning = "default"/pruning = "custom"/g' ~/.kid/config/app.toml
sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' ~/.kid/config/app.toml
sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' ~/.kid/config/app.toml

sudo tee <<EOF >/dev/null /etc/systemd/system/kid.service
[Unit]
Description=Kichain Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which kid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

kid unsafe-reset-all

SNAP_RPC="http://rpc1.nodejumper.io:28657"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" ~/.kid/config/config.toml

sudo systemctl daemon-reload && sudo systemctl enable kid \
&& sudo systemctl restart kid && sudo journalctl -u kid -f --no-hostname -o cat
