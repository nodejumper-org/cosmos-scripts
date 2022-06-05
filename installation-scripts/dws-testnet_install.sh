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

cd && rm -rf deweb && rm -rf .deweb
cd && git clone https://github.com/deweb-services/deweb.git
cd deweb && git checkout v0.2 && make install

dewebd version # 0.2

# replace nodejumper with your own moniker, if you'd like
dewebd config chain-id deweb-testnet-1
dewebd init "${1:-nodejumper}" --chain-id deweb-testnet-1

cd && wget https://raw.githubusercontent.com/deweb-services/deweb/main/genesis.json
mv -f genesis.json ~/.deweb/config/genesis.json
sha256sum ~/.deweb/config/genesis.json # 13bf101d673990cb39e6af96e3c7e183da79bd89f6d249e9dc797ae81b3573c2

cd && wget https://raw.githubusercontent.com/encipher88/deweb/main/addrbook.json
mv -f addrbook.json ~/.deweb/config/addrbook.json
sha256sum ~/.deweb/config/addrbook.json # ba7bea692350ca8918542a26cabd5616dbebe1ff109092cb1e98c864da58dabf

sed -i 's/^minimum-gas-prices *=.*/minimum-gas-prices = "0.0001udws"/g' ~/.deweb/config/app.toml
seeds=""
peers="9440fa39f85bea005514f0191d4550a1c9d310bb@rpc1-testnet.nodejumper.io:27656"
sed -i -e "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.deweb/config/config.toml

# in case of pruning
sed -i 's/pruning = "default"/pruning = "custom"/g' ~/.deweb/config/app.toml
sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' ~/.deweb/config/app.toml
sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' ~/.deweb/config/app.toml

sudo tee <<EOF >/dev/null /etc/systemd/system/dewebd.service
[Unit]
Description=DWS Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which dewebd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

dewebd unsafe-reset-all

rm -rf ~/.deweb/data && cd ~/.deweb

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/dws-testnet/ | egrep -o ">deweb-testnet-1.*\.tar.lz4" | tr -d ">")
wget -O - https://snapshots1-testnet.nodejumper.io/dws-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf -

sudo systemctl daemon-reload && sudo systemctl enable dewebd \
&& sudo systemctl restart dewebd && sudo journalctl -u dewebd -f --no-hostname -o cat