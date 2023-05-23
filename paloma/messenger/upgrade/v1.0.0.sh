sudo systemctl stop pigeond
sudo systemctl stop palomad

# install libwasm
cd || return
curl -L https://github.com/CosmWasm/wasmvm/raw/main/internal/api/libwasmvm.x86_64.so > libwasmvm.x86_64.so
sudo mv -f libwasmvm.x86_64.so /usr/lib/libwasmvm.x86_64.so

# build palomad binary
cd || return
rm -rf paloma
git clone https://github.com/palomachain/paloma.git
cd paloma || return
git checkout v1.0.0
make install
sudo mv -f $HOME/go/bin/palomad /usr/local/bin/palomad
palomad version # v1.0.0

# upgdate pigeon
curl -L https://github.com/palomachain/pigeon/releases/download/v1.0.0/pigeon_Linux_x86_64.tar.gz > pigeon.tar.gz
tar -xvzf pigeon.tar.gz
rm -rf pigeon.tar.gz
sudo mv -f pigeon /usr/local/bin/pigeon
pigeon version # v1.0.0

sudo systemctl start pigeond
sudo systemctl start palomad
