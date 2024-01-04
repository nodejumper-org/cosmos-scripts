# Clone project repository
cd $HOME
rm -rf node
git clone https://github.com/zeta-chain/node
cd node
git checkout ${tag}

# Build binary
make install-testnet