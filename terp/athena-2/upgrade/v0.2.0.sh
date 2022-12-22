sudo systemctl stop terpd

# backup chain data
cd || return
cp .terp .terp_backup

# build new binary
cd || return
rm -rf terp-core
git clone https://github.com/terpnetwork/terp-core.git
cd terp-core || return
git checkout v0.2.0
make install
terpd version # 0.2.0

# update genesis
curl -#  https://raw.githubusercontent.com/terpnetwork/test-net/master/athena-2/0.2.0/genesis.json > $HOME/.terp/config/genesis.json

# add skip upgrades flag to service file
sudo tee /etc/systemd/system/terpd.service > /dev/null << EOF
[Unit]
Description=TerpNetwork Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which terpd) start --unsafe-skip-upgrades 1497396
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start terpd
