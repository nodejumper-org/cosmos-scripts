# Stop the service
sudo systemctl stop babylond

# Clone project repository
cd && rm -rf babylon
git clone https://github.com/babylonchain/babylon
cd babylon
git checkout v0.8.3

# Build binary
make install

# Update node CLI configuration
nibid config chain-id bbn-test-3

# Download new genesis and addrbook files
curl -L https://snapshots-testnet.nodejumper.io/babylon-testnet/genesis.json > $HOME/.babylond/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/babylon-testnet/addrbook.json > $HOME/.babylond/config/addrbook.json

# Update seeds
sed -i -e 's|^seeds *=.*|seeds = "49b4685f16670e784a0fe78f37cd37d56c7aff0e@3.14.89.82:26656,9cb1974618ddd541c9a4f4562b842b96ffaf1446@3.16.63.237:26656"|' $HOME/.babylond/config/config.toml

# Reset node data
babylond tendermint unsafe-reset-all --home $HOME/.babylond --keep-addr-book

# Download latest chain data snapshot
curl "https://snapshots-testnet.nodejumper.io/babylon-testnet/babylon-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.babylond"

# Start the service and check the logs
sudo systemctl start babylond.service