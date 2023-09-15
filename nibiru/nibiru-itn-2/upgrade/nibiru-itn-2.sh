sudo systemctl stop nibid

cd || return
rm -rf nibiru
git clone https://github.com/NibiruChain/nibiru
cd nibiru || return
git checkout v0.21.9
make install

nibid config chain-id nibiru-itn-2

curl -s https://rpc.itn-2.nibiru.fi/genesis | jq -r .result.genesis > $HOME/.nibid/config/genesis.json

SEEDS="3f472746f46493309650e5a033076689996c8881@nibiru-testnet.rpc.kjnodes.com:13959"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.nibid/config/config.toml

nibid tendermint unsafe-reset-all --home $HOME/.nibid

curl -s https://snapshots-testnet.nodejumper.io/nibiru-testnet/addrbook.json > $HOME/.nibid/config/addrbook.json

sudo systemctl start nibid
