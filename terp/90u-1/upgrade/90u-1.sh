sudo systemctl stop terpd

# build new binary
cd || return
rm -rf terp-core
git clone https://github.com/terpnetwork/terp-core.git
cd terp-core || return
git checkout v1.0.0-stable
make install
terpd version # 1.0.0-stable-4-g9bb91af

# update genesis
curl -s https://raw.githubusercontent.com/terpnetwork/test-net/master/90u-1/genesis.json > $HOME/.terp/config/genesis.json

# set minimum gas price
sed -i 's/minimum-gas-prices = "[^"]*"/minimum-gas-prices = "0.0002uthiol"/' $HOME/.terp/config/app.toml

# update seeds and peers
SEEDS="3e1265ffbacf6a7bac355b0e565f0ad0e4e4c5a0@192.241.135.8:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.terp/config/config.toml

# set new chain-id and reset chain data
terpd config chain-id 90u-1
terpd tendermint unsafe-reset-all --home $HOME/.terp

sudo systemctl start terpd
