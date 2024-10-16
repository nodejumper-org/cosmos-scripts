# Download binary
cd $HOME
curl -s https://snapshots-testnet.nodejumper.io/soarchain/soarchaind > soarchaind
chmod +x soarchaind
mkdir -p $HOME/go/bin/
mv soarchaind $HOME/go/bin/

# Install libwasmvm
curl -L https://snapshots-testnet.nodejumper.io/soarchain/libwasmvm.x86_64.so > libwasmvm.x86_64.so
sudo mv libwasmvm.x86_64.so /var/lib/libwasmvm.x86_64.so
