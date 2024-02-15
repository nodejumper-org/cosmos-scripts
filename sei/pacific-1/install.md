# Sei Node Installation Guide

## Minimum System Requirements

- **CPU**: 16 Cores / 16 Threads
- **Memory**: 64 GB RAM
- **Disk**: 1 TB NVMe

## Installation Steps

### Step 1: Create User
Create a new user named `sei` and switch to it.
```bash
sudo adduser sei --disabled-password --gecos "" -q
echo "sei ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
sudo -u sei -i
```

### Step 2: Install Dependencies
Update your package list and install necessary dependencies.
```bash
sudo apt update
sudo apt install -y curl git jq lz4 build-essential
```

### Step 3: Install Go
Download and install the Go programming language.
```bash
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.21.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
source $HOME/.bash_profile
```

### Step 4: Clone Project Repository and Build Binary
Clone the `sei-chain` repository and checkout the desired version.
```bash
cd
rm -rf sei-chain
git clone https://github.com/sei-protocol/sei-chain.git
cd sei-chain
git checkout 3.6.1

make install
```

### Step 5: Initialize and Configure Node
Initialize Node and set up your node's CLI configuration.
```bash
seid init "YOUR_NODE_NAME_HERE" --chain-id pacific-1
seid config chain-id pacific-1
seid config keyring-backend file
```

### Step 6: Download Genesis File
```bash
curl -s https://raw.githubusercontent.com/sei-protocol/testnet/main/pacific-1/genesis.json > $HOME/.sei/config/genesis.json
```

### Step 7: Set Seeds
```bash
SEEDS="400f3d9e30b69e78a7fb891f60d76fa3c73f0ecc@sei.rpc.kjnodes.com:16859,20e1000e88125698264454a884812746c2eb4807@seeds.lavenderfive.com:11956,ebc272824924ea1a27ea3183dd0b9ba713494f83@sei-mainnet-seed.autostake.com:26806,c28827cb96c14c905b127b92065a3fb4cd77d7f6@seeds.whispernode.com:11956"
sed -i 's|^bootstrap-peers *=.*|bootstrap-peers = "'$SEEDS'"|' $HOME/.sei/config/config.toml
```

### Step 8: Adjust Configuration
Set minimum gas prices, enable RPC and allow CORS.
```bash
sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.1usei"|g' $HOME/.sei/config/app.toml

sed -i \
  -e 's|laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|g' \
  -e 's|^cors_allowed_origins *=.*|cors_allowed_origins = ["*"]|g' $HOME/.sei/config/config.toml
```

### Step 9: Download Latest Chain Data Snapshot
Visit https://polkachu.com/tendermint_snapshots/sei to find the latest snapshot link
```bash
# Example command to download and extract the snapshot
# curl -o - -L https://snapshots.polkachu.com/snapshots/sei/sei_58061725.tar.lz4 | lz4 -c -d - | tar -x -C $HOME/.sei
curl -o - -L <LINK_TO_SNAPSHOT> | lz4 -c -d - | tar -x -C $HOME/.sei
```

### Step 10: Create and Enable a System Service
```bash
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
```

### Step 12: Start the Service and Check the Logs
```bash
sudo systemctl start seid
sudo journalctl -u seid -f --no-hostname -o cat
```
