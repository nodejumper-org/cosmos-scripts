# Stop the service
sudo systemctl stop wardend

# Download and install the new binary
cd && wget https://github.com/warden-protocol/wardenprotocol/releases/download/v0.3.2/wardend_Linux_x86_64.zip
unzip wardend_Linux_x86_64.zip
rm -rf wardend_Linux_x86_64.zip
chmod +x wardend
sudo mv wardend $(which wardend)

# Download new genesis file
cd && curl -L https://buenavista-genesis.s3.eu-west-1.amazonaws.com/genesis.json.tar.xz | tar xJf -
mv genesis.json $HOME/.warden/config/genesis.json
rm -rf genesis.json.tar.xz

# Reset chain data
cp $HOME/.warden/data/priv_validator_state.json $HOME/.warden/priv_validator_state.json.backup
wardend tendermint unsafe-reset-all --keep-addr-book
rm -rf $HOME/.warden/wasm

# Download snapshot
curl https://snapshots-testnet.nodejumper.io/wardenprotocol-testnet/wardenprotocol-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.warden
mv $HOME/.warden/priv_validator_state.json.backup $HOME/.warden/data/priv_validator_state.json

# Start the service
sudo systemctl start wardend
