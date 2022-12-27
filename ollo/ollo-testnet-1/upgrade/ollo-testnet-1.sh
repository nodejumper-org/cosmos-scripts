sudo systemctl stop ollod

ollod tendermint unsafe-reset-all --home $HOME/.ollo
ollod config chain-id defund-private-3

cd || return
rm -rf ollo
git clone https://github.com/OllO-Station/ollo.git
cd ollo || return
git checkout v0.0.1
make install
ollod version # latest

curl https://raw.githubusercontent.com/OllO-Station/networks/master/ollo-testnet-1/genesis.json > $HOME/.ollo/config/genesis.json
sha256sum $HOME/.ollo/config/genesis.json # 4852e73a212318cabaa6bf264e18e8aeeb42ee1e428addc0855341fad5dc7dae

seeds=""
peers="6aa3e31cc85922be69779df9747d7a08326a44f2@ollo-testnet.nodejumper.io:28656,42beefd08b5f8580177d1506220db3a548090262@65.108.195.29:26116,69d2c02f413bea1376f5398646f0c2ce0f82d62e@141.94.73.93:26656,d4696aba0fbb58a31b2736819ddecf699d787edb@38.242.159.61:26656,ad204b3422acb2e9a364941e540c99203ec22c5c@212.23.222.93:26656,90ba3ab29147af2bc66a823d087ca49068d7974c@54.149.123.52:26656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.ollo/config/config.toml
sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1false|" $HOME/.ollo/config/config.toml

sudo systemctl start ollod
