#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/logo/logo.sh)

sudo apt update
sudo apt install -y make gcc jq curl git snapd
sudo snap install lz4

if [ ! -f "/usr/local/go/bin/go" ]; then
  . <(curl -s "https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/installation-scripts/go_install.sh")
  . .bash_profile
fi
go version # go version goX.XX.X linux/amd64

cd || return
rm -rf osmosis
git clone https://github.com/osmosis-labs/osmosis
cd osmosis || return
git checkout v9.0.0
make install
osmosisd version # v9.0.0

# replace nodejumper with your own moniker, if you'd like
osmosisd config chain-id osmosis-1
osmosisd init "${1:-nodejumper}" --chain-id osmosis-1

curl https://github.com/osmosis-labs/networks/raw/main/osmosis-1/genesis.json > $HOME/.osmosisd/config/genesis.json
sha256sum $HOME/.osmosisd/config/genesis.json # 1cdb76087fabcca7709fc563b44b5de98aaf297eedc8805aa2884999e6bab06d

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uosmo"|g' $HOME/.osmosisd/config/app.toml
seeds="21d7539792ee2e0d650b199bf742c56ae0cf499e@162.55.132.230:2000,295b417f995073d09ff4c6c141bd138a7f7b5922@65.21.141.212:2000,ec4d3571bf709ab78df61716e47b5ac03d077a1a@65.108.43.26:2000,4cb8e1e089bdf44741b32638591944dc15b7cce3@65.108.73.18:2000,f515a8599b40f0e84dfad935ba414674ab11a668@osmosis.blockpane.com:26656,6bcdbcfd5d2c6ba58460f10dbcfde58278212833@osmosis.artifact-staking.io:26656"
peers="83c06bc290b6dffe05aa9cec720bedfc118afcbc@rpc2.nodejumper.io:35656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.osmosisd/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.osmosisd/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.osmosisd/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.osmosisd/config/app.toml
sed -i 's/snapshot-interval *=.*/snapshot-interval = 0/g' $HOME/.osmosisd/config/app.toml

sudo tee /etc/systemd/system/osmosisd.service  > /dev/null << EOF
[Unit]
Description=Osmosis Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which osmosisd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

osmosisd unsafe-reset-all --home $HOME/.osmosisd
rm -rf $HOME/.osmosisd/data
cd $HOME/.osmosisd || return

SNAP_NAME=$(curl -s https://snapshots2.nodejumper.io/osmosis/ | egrep -o ">osmosis-1.*\.tar.lz4" | tr -d ">")
curl https://snapshots2.nodejumper.io/osmosis/"${SNAP_NAME}" | lz4 -dc - | tar -xf -

sudo systemctl daemon-reload
sudo systemctl enable osmosisd
sudo systemctl restart osmosisd
