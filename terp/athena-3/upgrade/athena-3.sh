sudo systemctl stop terpd

# build new binary
cd || return
rm -rf terp-core
git clone https://github.com/terpnetwork/terp-core.git
cd terp-core || return
git checkout 2b8926a
make install
terpd version # 0.2.0-3-g2b8926a

# update genesis
curl -s https://raw.githubusercontent.com/terpnetwork/test-net/master/athena-3/genesis.json > $HOME/.terp/config/genesis.json

# check sha256sum
sha256sum ~/.terp/config/genesis.json # 262bd0d964a46a7d603427fe02e2508f07d20676b92ec57b60fc543f4c643b4e

# download fresh addrbook
curl -s https://snapshots-testnet.nodejumper.io/terpnetwork-testnet/addrbook.json > $HOME/.terp/config/addrbook.json

# erase chain data
terpd tendermint unsafe-reset-all --home $HOME/.terp --keep-addr-book

# set new chain-id
sed -i 's|^chain-id *=.*|chain-id = "athena-3"|g' $HOME/.terp/config/client.toml

# set service file to default
sudo tee /etc/systemd/system/terpd.service > /dev/null << EOF
[Unit]
Description=TerpNetwork Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which terpd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start terpd
