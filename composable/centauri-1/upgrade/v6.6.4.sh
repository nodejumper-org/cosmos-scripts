# Install new binary
cd && rm -rf composable-cosmos && rm -rf composable-centauri
git clone https://github.com/ComposableFi/composable-cosmos
cd composable-cosmos
git checkout v6.6.4
make install

# Remove old service
sudo systemctl stop centaurid
sudo systemctl disable centaurid
sudo rm /etc/systemd/system/centaurid.service

# Create a new service
sudo tee /etc/systemd/system/picad.service > /dev/null << EOF
[Unit]
Description=Picasso node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which picad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable picad.service

sudo systemctl start picad
