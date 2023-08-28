sudo systemctl stop defundd

cd || return
rm -rf defund
git clone https://github.com/defund-labs/defund.git
cd defund || return
git checkout v0.2.6
make install
defundd version # 0.2.6

defundd tendermint unsafe-reset-all --home $HOME/.defund
defundd config chain-id orbit-alpha-1

curl -s https://raw.githubusercontent.com/defund-labs/testnet/main/orbit-alpha-1/genesis.json > ~/.defund/config/genesis.json
curl -s https://snapshots-testnet.nodejumper.io/defund-testnet/addrbook.json > $HOME/.defund/config/addrbook.json

SEEDS="f902d7562b7687000334369c491654e176afd26d@170.187.157.19:26656,2b76e96658f5e5a5130bc96d63f016073579b72d@rpc-1.defund.nodes.guru:45656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.defund/config/config.toml
sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1false|" $HOME/.defund/config/config.toml

SNAP_NAME=$(curl -s https://snapshots-testnet.nodejumper.io/defund-testnet/info.json | jq -r .fileName)
curl "https://snapshots-testnet.nodejumper.io/defund-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.defund"

# make sure node is synced and create new validator, if needed

sudo systemctl start defundd
