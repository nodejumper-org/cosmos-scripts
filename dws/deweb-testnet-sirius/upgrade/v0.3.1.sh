sudo systemctl stop dewebd

# remove old chain data and binary
dewebd tendermint unsafe-reset-all --home $HOME/.deweb
rm "$(which dewebd)"

# install new binary
cd || return
rm -rf deweb
git clone https://github.com/deweb-services/deweb.git
cd deweb || return
git checkout v0.3.1
make install
dewebd version # 0.3.1

# config new chain
dewebd config chain-id $CHAIN_ID
curl -s https://raw.githubusercontent.com/deweb-services/deweb/main/genesis.json > $HOME/.deweb/config/genesis.json
sha256sum $HOME/.deweb/config/genesis.json # 5316dc5abf1bc46813b673e920cb6faac06850c4996da28d343120ee0d713ab9

SEEDS="2b1aebd0029570c20932bf7a17b3d7e67cbacc52@31.44.6.134:26656"
PEERS="c5b45045b0555c439d94f4d81a5ec4d1a578f98c@dws-testnet.nodejumper.io:27656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.deweb/config/config.toml
sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1false|" $HOME/.deweb/config/config.toml

sudo systemctl start dewebd
