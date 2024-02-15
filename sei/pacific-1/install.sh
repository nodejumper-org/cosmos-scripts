#!/bin/bash

# Create user sei and switch to it
sudo adduser sei --disabled-password --gecos "" -q
sudo -u sei -i

# Install dependencies
sudo apt update
sudo apt install -y curl git jq lz4 build-essential

# Install Go
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.21.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
source .bash_profile

# Clone project repository
cd && rm -rf sei-chain
git clone https://github.com/sei-protocol/sei-chain.git
cd sei-chain
git checkout 3.6.1

# Build binary
make install

# Set node CLI configuration
seid config chain-id pacific-1
seid config keyring-backend file

# Initialize the node
seid init "YOUR_NODE_NAME_HERE" --chain-id pacific-1

# Download genesis
curl -s https://raw.githubusercontent.com/sei-protocol/testnet/main/pacific-1/genesis.json > $HOME/.sei/config/genesis.json

# Set seeds
SEEDS="400f3d9e30b69e78a7fb891f60d76fa3c73f0ecc@sei.rpc.kjnodes.com:16859,20e1000e88125698264454a884812746c2eb4807@seeds.lavenderfive.com:11956,ebc272824924ea1a27ea3183dd0b9ba713494f83@sei-mainnet-seed.autostake.com:26806,c28827cb96c14c905b127b92065a3fb4cd77d7f6@seeds.whispernode.com:11956"
sed -i 's|^bootstrap-peers *=.*|bootstrap-peers = "'$SEEDS'"|' $HOME/.sei/config/config.toml

# Set minimum-gas-prices
sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.1usei"|g' $HOME/.sei/config/app.toml

# Enable RPC
sed -i \
  -e 's|laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|g' \
  -e 's|^cors_allowed_origins *=.*|cors_allowed_origins = ["*"]|g' $HOME/.sei/config/config.toml

# Create a service
sudo tee /etc/systemd/system/seid.service > /dev/null << EOF
[Unit]
Description=Sei Protocol Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which seid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable seid

# Download latest chain data snapshot
# go to the Polkachu's website and download the latest snapshot
# https://polkachu.com/tendermint_snapshots/sei
# curl -o - -L <LINK_TO_SNAPSHOT> | lz4 -c -d - | tar -x -C $HOME/.sei

# Start the service
sudo systemctl start seid

# Check the logs
sudo journalctl -u seid -f --no-hostname -o cat
