#!/bin/bash

sudo systemctl stop celestia-appd

# set necessary vars
CHAIN_ID="mocha-3"
NODE_MONIKER=$(cat "$HOME/.celestia-app/config/config.toml" | grep moniker | grep -oP 'moniker = "\K[^"]+')

# backup priv_validator_key.json from mocha (optional)
cp $HOME/.celestia-app/config/priv_validator_key.json $HOME/priv_validator_key.json.backup

# remove mocha testnet data
rm -rf $HOME/.celestia-app
rm -rf $HOME/celestia-app
rm -rf networks
sudo rm "$(which celestia-appd)"

# install mocha-3 testnet
cd $HOME || return
rm -rf celestia-app
git clone https://github.com/celestiaorg/celestia-app.git
cd celestia-app || return
git checkout v0.13.3
make install
celestia-appd version # 0.13.3

celestia-appd config keyring-backend test
celestia-appd config chain-id $CHAIN_ID
celestia-appd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/celestiaorg/networks/master/mocha-3/genesis.json > $HOME/.celestia-app/config/genesis.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001utia"|g' $HOME/.celestia-app/config/app.toml

SEEDS=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/mocha-3/seeds.txt | tr -d '\n')
PEERS=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/mocha-3/peers.txt | tr -d '\n')
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.celestia-app/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.celestia-app/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.celestia-app/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.celestia-app/config/app.toml

# restore priv_validator_key.json from mamaki (optional)
cp $HOME/priv_validator_key.json.backup $HOME/.celestia-app/config/priv_validator_key.json

sudo systemctl start celestia-appd
