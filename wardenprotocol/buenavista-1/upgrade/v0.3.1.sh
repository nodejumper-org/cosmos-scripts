# Stop the service
sudo systemctl stop wardend

# Download and install the new binary
cd && wget https://github.com/warden-protocol/wardenprotocol/releases/download/v0.3.1/wardend_Linux_x86_64.zip
unzip wardend_Linux_x86_64.zip
rm -rf wardend_Linux_x86_64.zip
chmod +x wardend
sudo mv wardend $(which wardend)

# Download new genesis file
cd && wget https://buenavista-genesis.s3.eu-west-1.amazonaws.com/genesis.json.tar.xz
tar --overwrite -xvf genesis.json.tar.xz
rm -rf genesis.json.tar.xz
mv genesis.json $HOME/.warden/config/genesis.json

# Reset chain data
wardend tendermint unsafe-reset-all --keep-addr-book

# Start the service
sudo systemctl start wardend
