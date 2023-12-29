# Download binary
cd $HOME
curl -s https://snapshots-testnet.nodejumper.io/arkeonetwork-testnet/arkeod > arkeod
chmod +x arkeod
mkdir -p $HOME/go/bin/
mv arkeod $HOME/go/bin/