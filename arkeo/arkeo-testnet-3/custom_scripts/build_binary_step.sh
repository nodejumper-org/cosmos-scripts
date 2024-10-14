# Clone project repository
cd && git clone https://github.com/arkeonetwork/arkeo
cd arkeo
git checkout master

# Build binary
TAG=testnet make install
