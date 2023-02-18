sudo systemctl stop terpd

# build new binary
cd || return
rm -rf terp-core
git clone https://github.com/terpnetwork/terp-core.git
cd terp-core || return
git checkout main
make install
terpd version # 0.4.0

# update genesis
curl -s https://raw.githubusercontent.com/terpnetwork/test-net/master/athena-4/genesis.json > $HOME/.terp/config/genesis.json

# check sha256sum
sha256sum ~/.terp/config/genesis.json # TODO: TBD

# erase chain data
terpd tendermint unsafe-reset-all --home $HOME/.terp --keep-addr-book

# set new chain-id
sed -i 's|^chain-id *=.*|chain-id = "athena-4"|g' $HOME/.terp/config/client.toml

sudo systemctl daemon-reload
sudo systemctl start terpd
