#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)

sudo apt update
sudo apt install -y make gcc jq curl git snapd
sudo snap install lz4

if [ ! -f "/usr/local/go/bin/go" ]; then
  . <(curl -s "https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/go_install.sh")
  . .bash_profile
fi
go version # go version goX.XX.X linux/amd64

cd || return
git clone https://github.com/ingenuity-build/quicksilver.git
cd quicksilver || return
git checkout v0.2.0
make install
quicksilverd version # v0.2.0

# replace nodejumper with your own moniker, if you'd like
quicksilverd config chain-id rhapsody-4
quicksilverd init "${1:-nodejumper}" --chain-id rhapsody-4

curl https://raw.githubusercontent.com/ingenuity-build/testnets/main/rhapsody/genesis.json > $HOME/.quicksilverd/config/genesis.json
sha256sum $HOME/.quicksilverd/config/genesis.json #

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001qck"|g' $HOME/.quicksilverd/config/app.toml
seeds="dd3460ec11f78b4a7c4336f22a356fe00805ab64@seed.rhapsody-4.quicksilver.zone:26656"
peers=""
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.quicksilverd/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.quicksilverd/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.quicksilverd/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.quicksilverd/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.quicksilverd/config/app.toml

sudo tee /etc/systemd/system/quicksilverd.service > /dev/null << EOF
[Unit]
Description=Quicksilver Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which quicksilverd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

quicksilverd unsafe-reset-all
rm -rf $HOME/.quicksilverd/data
cd $HOME/.quicksilverd || return

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/quicksilver/ | egrep -o ">rhapsody-4.*\.tar.lz4" | tr -d ">")
echo "Downloading a snapshot..."
curl -# https://snapshots1-testnet.nodejumper.io/quicksilver/"${SNAP_NAME}" | lz4 -dc - | tar -xf -

sudo systemctl daemon-reload
sudo systemctl enable quicksilverd
sudo systemctl restart quicksilverd
