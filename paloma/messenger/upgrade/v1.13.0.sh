# upgrade CosmWasm
cd $HOME
curl -L https://github.com/CosmWasm/wasmvm/releases/download/v1.5.0/libwasmvm.x86_64.so > libwasmvm.x86_64.so
sudo mv -f libwasmvm.x86_64.so /usr/lib/libwasmvm.x86_64.so

# upgrade paloma
cd && rm -rf paloma
git clone -b v1.13.0 https://github.com/palomachain/paloma.git
cd paloma
make install
sudo mv -f $HOME/go/bin/palomad "$(which palomad)"

# upgrade pigeon
cd && rm -rf pigeon
git clone -b v1.11.0 https://github.com/palomachain/pigeon
cd pigeon
make build
sudo mv -f build/pigeon "$(which pigeon)"

sudo systemctl restart pigeond
sudo systemctl restart palomad
