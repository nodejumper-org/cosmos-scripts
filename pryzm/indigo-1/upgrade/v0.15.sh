sudo systemctl stop pryzmd

# Download new binary
cd $HOME
curl -s https://storage.googleapis.com/pryzm-zone/core/0.15.0/pryzmd-0.15.0-linux-amd64 > pryzmd
chmod +x pryzmd
sudo mv pryzmd $(which pryzmd)

sudo systemctl start pryzmd
