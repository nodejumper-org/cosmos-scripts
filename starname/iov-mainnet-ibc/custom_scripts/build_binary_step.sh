# Clone project repository
cd $HOME
rm -rf starnamed
git clone https://github.com/iov-one/starnamed.git
cd starnamed
git checkout ${tag}
make build

# Install libwasmvm
curl -L https://github.com/CosmWasm/wasmvm/raw/v0.13.0/api/libwasmvm.so > libwasmvm.so
sudo mv -f libwasmvm.so /lib/libwasmvm.so

# Build binary
make build
mkdir -p $HOME/go/bin
sudo cp $HOME/starnamed/build/starnamed $HOME/go/bin