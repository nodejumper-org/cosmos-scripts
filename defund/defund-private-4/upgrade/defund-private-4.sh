sudo systemctl stop defundd

cd || return
rm -rf defund
git clone https://github.com/defund-labs/defund.git
cd defund || return
git checkout v0.2.2
make install
defundd version # 0.2.2

defundd tendermint unsafe-reset-all --home $HOME/.defund
defundd config chain-id defund-private-4

curl -s https://raw.githubusercontent.com/defund-labs/testnet/main/defund-private-4/genesis.json > ~/.defund/config/genesis.json

SEEDS="d837b7f78c03899d8964351fb95c78e84128dff6@174.83.6.129:30791,f03f3a18bae28f2099648b1c8b1eadf3323cf741@162.55.211.136:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.defund/config/config.toml
sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1false|" $HOME/.defund/config/config.toml

SNAP_NAME=$(curl -s https://snapshots-testnet.nodejumper.io/defund-testnet/ | egrep -o ">defund-private-4.*\.tar.lz4" | tr -d ">")
curl https://snapshots-testnet.nodejumper.io/defund-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf - -C $HOME/.defund

sudo systemctl start defundd
