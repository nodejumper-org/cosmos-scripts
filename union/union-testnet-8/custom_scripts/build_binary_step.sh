# Download binary
cd $HOME
mkdir -p $HOME/go/bin
curl -L https://snapshots-testnet.nodejumper.io/union-testnet/uniond-${tag}-linux-amd64 > $HOME/go/bin/uniond
chmod +x $HOME/go/bin/uniond