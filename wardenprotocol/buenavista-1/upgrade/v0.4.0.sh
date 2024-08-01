### Upgrade warden binary
# Stop the service
sudo systemctl stop wardend

# Backup a validator state
cp $HOME/.warden/data/priv_validator_state.json $HOME/priv_validator_state_WARDEN.json

# Download and install the new binary
cd && wget https://github.com/warden-protocol/wardenprotocol/releases/download/v0.4.0/wardend_Linux_x86_64.zip
unzip wardend_Linux_x86_64.zip
rm -rf wardend_Linux_x86_64.zip
chmod +x wardend
sudo mv wardend $(which wardend)

# Update app.toml with new config
sed -i '1i\\
$ a\
[oracle]\
enabled = "true"\
oracle_address = "localhost:8080"\
client_timeout = "2s"\
metrics_enabled = "true"' $HOME/.warden/config/app.toml

# Start the service
sudo systemctl start wardend

### Install and configure slinky
# Download a slinky binary
cd && curl -Ls https://github.com/skip-mev/slinky/releases/download/v1.0.4/slinky-1.0.4-linux-amd64.tar.gz > slinky-1.0.4-linux-amd64.tar.gz
tar -xzf slinky-1.0.4-linux-amd64.tar.gz
sudo mv slinky-1.0.4-linux-amd64/slinky $HOME/go/bin/slinky

# Determine the node's gRPC port
GRPC_PORT=$(grep 'address = ' "$HOME/.warden/config/app.toml" | awk -F: '{print $NF}' | grep '90"$' | tr -d '"')

# Create a systemd service for slinky
sudo tee /etc/systemd/system/warden-slinky.service > /dev/null << EOF
[Unit]
Description=Slinky for Warden Protocol service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which slinky) --market-map-endpoint="127.0.0.1:$GRPC_PORT"
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable warden-slinky
sudo systemctl start warden-slinky
