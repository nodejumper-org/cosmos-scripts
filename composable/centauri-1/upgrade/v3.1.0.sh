# stop and remove old service
sudo systemctl stop banksyd
sudo rm /etc/systemd/system/banksyd.service
sudo systemctl disable banksyd

# build new binary
cd || return
rm -rf composable-testnet
git clone https://github.com/notional-labs/composable-testnet.git
cd composable-testnet || return
git checkout v3.1.0
make install

# setup new service
sudo tee /etc/systemd/system/centaurid.service > /dev/null << EOF
[Unit]
Description=Composable Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which centaurid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
WorkingDirectory=$HOME
[Install]
WantedBy=multi-user.target
EOF

# start new service
sudo systemctl daemon-reload
sudo systemctl enable centaurid
sudo systemctl start centaurid
