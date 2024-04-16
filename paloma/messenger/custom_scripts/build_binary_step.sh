# Clone project repository
cd $HOME
rm -rf paloma
git clone https://github.com/palomachain/paloma
cd paloma
git checkout ${tag}

# Install libwasmvm
curl -L https://github.com/CosmWasm/wasmvm/releases/download/v1.5.0/libwasmvm.x86_64.so > libwasmvm.x86_64.so
sudo mv -f libwasmvm.x86_64.so /usr/lib/libwasmvm.x86_64.so

# Build binary
make install
