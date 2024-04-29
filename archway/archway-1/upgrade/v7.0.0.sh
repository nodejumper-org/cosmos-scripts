# Clone project repository
cd && rm -rf archway
git clone https://github.com/archway-network/archway
cd archway
git checkout v7.0.0

# Build binary
make install

sudo systemctl restart archwayd
