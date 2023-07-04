sudo systemctl stop centaurid

cd || return
rm -rf composable-centauri
git clone https://github.com/notional-labs/composable-centauri
cd composable-centauri || return
git checkout v3.2.2
make install
centaurid rollback
cd $HOME/.banksy
rm -rf wasm_client_data
wget https://github.com/notional-labs/notional/raw/master/infrastructure/archive/wasmclient.tar.gz
tar -xzvf wasmclient.tar.gz

sudo systemctl start centaurid
