sudo systemctl stop banksyd

cd || return
rm -rf composable-testnet
git clone https://github.com/notional-labs/composable-testnet.git
cd composable-testnet || return
git checkout v3.0.0
make install

sudo rm /etc/systemd/system/banksyd.service
sudo systemctl disable banksyd

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

sudo systemctl daemon-reload
sudo systemctl enable centaurid
sudo systemctl start centaurid
