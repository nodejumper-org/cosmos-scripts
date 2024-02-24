sudo systemctl stop archwayd

# Clone project repository
cd && rm -rf archway
git clone https://github.com/archway-network/archway
cd archway
git checkout v6.0.1

# Build binary
make install

sudo systemctl start archwayd
