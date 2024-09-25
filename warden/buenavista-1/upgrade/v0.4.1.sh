# Stop the service
sudo systemctl stop wardend

# Backup a validator state
cp $HOME/.warden/data/priv_validator_state.json $HOME/priv_validator_state.json

# Download and install the new binary
cd && wget https://github.com/warden-protocol/wardenprotocol/releases/download/v0.4.1/wardend_Linux_x86_64.zip
unzip wardend_Linux_x86_64.zip
rm -rf wardend_Linux_x86_64.zip
chmod +x wardend
sudo mv wardend $(which wardend)

# Start the service
sudo systemctl start wardend
