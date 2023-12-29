# Clone project repository
cd $HOME
rm -rf node
git clone https://github.com/zeta-chain/node
cd node
git checkout v11.0.0

# Build binary
make install-testnet