sudo systemctl stop terpd

# build new binary
cd || return
rm -rf terp-core
git clone https://github.com/terpnetwork/terp-core.git
cd terp-core || return
git checkout v0.4.0
make install
terpd version # 0.4.0

# update genesis
curl -s https://raw.githubusercontent.com/terpnetwork/test-net/master/athena-4/genesis.json > $HOME/.terp/config/genesis.json

# check sha256sum
sha256sum ~/.terp/config/genesis.json # ac718e966397e08baa920d1a51aff97c59a166bbe0110539bc70f0ef5500b5f9

# erase chain data
terpd tendermint unsafe-reset-all --home $HOME/.terp --keep-addr-book

# set new chain-id
sed -i 's|^chain-id *=.*|chain-id = "athena-4"|g' $HOME/.terp/config/client.toml

sudo systemctl start terpd
