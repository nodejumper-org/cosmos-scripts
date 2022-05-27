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

cd && rm -rf anone && rm -rf .anone
cd && git clone https://github.com/notional-labs/anone
cd anone && git checkout testnet-1.0.3 && make install

anoned version # testnet-1.0.3

# replace nodejumper with your own moniker, if you'd like
anoned config chain-id anone-testnet-1
anoned init "${1:-nodejumper}" --chain-id anone-testnet-1

cd && wget https://raw.githubusercontent.com/notional-labs/anone/master/networks/testnet-1/genesis.json
mv -f genesis.json ~/.anone/config/genesis.json
sha256sum ~/.anone/config/genesis.json # ba7bea692350ca8918542a26cabd5616dbebe1ff109092cb1e98c864da58dabf

sed -i 's/^minimum-gas-prices *=.*/minimum-gas-prices = "0.0001uan1"/g' ~/.anone/config/app.toml
seeds=""
peers="3137535a0d6cc552bd44512ac6a11f4a41c3b3e4@rpc1-testnet.nodejumper.io:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$seeds\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.anone/config/config.toml

# in case of pruning
sed -i 's/pruning = "default"/pruning = "custom"/g' ~/.anone/config/app.toml
sed -i 's/pruning-keep-recent = "0"/pruning-keep-recent = "100"/g' ~/.anone/config/app.toml
sed -i 's/pruning-interval = "0"/pruning-interval = "10"/g' ~/.anone/config/app.toml

sudo tee <<EOF >/dev/null /etc/systemd/system/anoned.service
[Unit]
Description=Another-1 Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which anoned) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

anoned unsafe-reset-all

rm -rf ~/.anone/data && cd ~/.anone

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/another1-testnet/ | egrep -o ">anone-testnet-1.*\.tar.lz4" | tr -d ">")
wget -O - https://snapshots1-testnet.nodejumper.io/another1-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf -

sudo systemctl daemon-reload && sudo systemctl enable anoned \
&& sudo systemctl restart anoned && sudo journalctl -u anoned -f --no-hostname -o cat