# Stop the service
sudo systemctl stop wardend

# Backup a validator state
cp $HOME/.warden/data/priv_validator_state.json $HOME/priv_validator_state_WARDEN.json

# Download and install the new binary
cd && wget https://github.com/warden-protocol/wardenprotocol/releases/download/v0.3.1/wardend_Linux_x86_64.zip
unzip wardend_Linux_x86_64.zip
rm -rf wardend_Linux_x86_64.zip
chmod +x wardend
sudo mv wardend $(which wardend)

# Download the genesis file
cd && wget https://buenavista-genesis.s3.eu-west-1.amazonaws.com/genesis.json.tar.xz
tar --overwrite -xvf genesis.json.tar.xz
rm -rf genesis.json.tar.xz
mv genesis.json $HOME/.warden/genesis.json

# Reset chain data
rm -rf $HOME/.warden/data
rm -rf $HOME/.warden/wasm

# Download snapshot
curl https://snapshots.liveraven.net/snapshots/testnet/warden-protocol/warden_2024-08-01_1533919_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.warden

# Restore a validator state
cp $HOME/priv_validator_state_WARDEN.json $HOME/.warden/data/priv_validator_state.json

# Update the service configuration
sudo tee /etc/systemd/system/wardend.service > /dev/null << EOF
[Unit]
Description=Warden Protocol node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which wardend) start --unsafe-skip-upgrades 1534500
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload

# Start the service
sudo systemctl start wardend
