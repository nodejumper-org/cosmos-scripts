sudo systemctl stop terpd

cd || return
rm -rf terp-core
git clone https://github.com/terpnetwork/terp-core.git
cd terp-core || return
git checkout v0.1.2
make install
terpd version # v0.1.2

terpd config chain-id athena-2

cp $HOME/.terp/data/priv_validator_state.json $HOME/.terp/priv_validator_state.json.backup
terpd tendermint unsafe-reset-all --home $HOME/.terp

curl -s https://raw.githubusercontent.com/terpnetwork/test-net/master/athena-2/genesis.json > $HOME/.terp/config/genesis.json
sha256sum $HOME/.terp/config/genesis.json # b2acc7ba63b05f5653578b05fc5322920635b35a19691dbafd41ef6374b1bc9a

seeds=""
peers="15f5bc75be9746fd1f712ca046502cae8a0f6ce7@terp-testnet.nodejumper.io:26656,7e5c0b9384a1b9636f1c670d5dc91ba4721ab1ca@23.88.53.28:36656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.terp/config/config.toml

mv $HOME/.terp/priv_validator_state.json.backup $HOME/.terp/data/priv_validator_state.json

sudo systemctl restart terpd
