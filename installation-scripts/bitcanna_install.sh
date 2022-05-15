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

cd && rm -rf bcna && rm -rf .bcna
git clone https://github.com/BitCannaGlobal/bcna.git
cd bcna && git checkout v.1.3.1 && make install

bcnad version # .1.3.1

# replace nodejumper with your own moniker, if you'd like
bcnad config chain-id bitcanna-1
bcnad init "${1:-nodejumper}" --chain-id bitcanna-1

cd && wget https://raw.githubusercontent.com/BitCannaGlobal/bcna/main/genesis.json
mv -f genesis.json ~/.bcna/config/genesis.json
jq -S -c -M '' ~/.bcna/config/genesis.json | shasum -a 256 # 2c8766d7547d6862f776269f67eed86d30d6a3ddfcaf60fe0461aa392060a35f  -

sed -i 's/^minimum-gas-prices *=.*/minimum-gas-prices = "0.0001ubcna"/g' ~/.bcna/config/app.toml
seeds="d6aa4c9f3ccecb0cc52109a95962b4618d69dd3f@seed1.bitcanna.io:26656,23671067d0fd40aec523290585c7d8e91034a771@seed2.bitcanna.io:26656"
peers="45589e6147e36dda9e429668484d7614fb25b142@rpc1.nodejumper.io:27656"
sed -i -e "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.bcna/config/config.toml

# in case of pruning
sed -i 's/pruning = "default"/pruning = "custom"/g' ~/.bcna/config/app.toml
sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' ~/.bcna/config/app.toml
sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' ~/.bcna/config/app.toml

sudo tee <<EOF >/dev/null /etc/systemd/system/bcnad.service
[Unit]
Description=Bitcanna Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which bcnad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

bcnad unsafe-reset-all

SNAP_RPC="http://rpc1.nodejumper.io:27657"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" ~/.bcna/config/config.toml

sudo systemctl daemon-reload && sudo systemctl enable bcnad \
&& sudo systemctl restart bcnad && sudo journalctl -u bcnad -f --no-hostname -o cat
