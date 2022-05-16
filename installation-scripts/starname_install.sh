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
sudo apt install snapd -y && sudo snap install lz4

cd && wget https://github.com/CosmWasm/wasmvm/raw/v0.13.0/api/libwasmvm.so
sudo mv -f libwasmvm.so /lib/libwasmvm.so

cd && rm -rf starnamed && rm -rf .starnamed
git clone https://github.com/iov-one/starnamed.git
cd starnamed && git checkout v0.10.13 && make install

starnamed version # v0.10.13

# replace nodejumper with your own moniker, if you'd like
starnamed init "${1:-nodejumper}" --chain-id iov-mainnet-ibc

cd && wget https://gist.githubusercontent.com/davepuchyr/6bea7bf369064d118195e9b15ea08a0f/raw/cf66fd02ea9336bd79cbc47dd47dcd30aad7831c/genesis.json
mv -f genesis.json ~/.starnamed/config/genesis.json
sha256sum ~/.starnamed/config/genesis.json # e20eb984b3a85eb3d2c76b94d1a30c4b3cfa47397d5da2ec60dca8bef6d40b17

sed -i 's/^minimum-gas-prices *=.*/minimum-gas-prices = "0.0001uiov"/g' ~/.starnamed/config/app.toml
seeds=""
peers="3180fdc5e477e675acd22e63477ce3a2db20edf9@rpc2.nodejumper.io:34656"
sed -i -e "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.starnamed/config/config.toml

# in case of pruning
sed -i 's/pruning = "default"/pruning = "custom"/g' ~/.starnamed/config/app.toml
sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' ~/.starnamed/config/app.toml
sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' ~/.starnamed/config/app.toml

sudo tee <<EOF >/dev/null /etc/systemd/system/starnamed.service
[Unit]
Description=Starname Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which starnamed) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

starnamed unsafe-reset-all

rm -rf ~/.starnamed/data && cd ~/.starnamed

SNAP_NAME=$(curl -s https://snapshots2.nodejumper.io/starname/ | egrep -o ">iov-mainnet-ibc.*\.tar.lz4" | tr -d ">")
wget -O - https://snapshots2.nodejumper.io/starname/${SNAP_NAME} | lz4 -dc - | tar -xf -

sudo systemctl daemon-reload && sudo systemctl enable starnamed \
&& sudo systemctl restart starnamed && sudo journalctl -u starnamed -f --no-hostname -o cat