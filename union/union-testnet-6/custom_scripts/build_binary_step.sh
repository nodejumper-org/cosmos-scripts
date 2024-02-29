# Download binary
cd $HOME && mkdir -p $HOME/go/bin
curl -L https://snapshots-testnet.nodejumper.io/union-testnet/uniond-0.20.0-linux-amd64 > $HOME/go/bin/uniond
sudo chmod +x $HOME/go/bin/uniond