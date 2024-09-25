# Download binary
cd $HOME
curl -s https://raw.githubusercontent.com/soar-robotics/testnet-binaries/main/${tag}/ubuntu22.04/soarchaind > soarchaind
chmod +x soarchaind
mkdir -p $HOME/go/bin/
mv soarchaind $HOME/go/bin/

# Install libwasmvm
curl -L https://snapshots-testnet.nodejumper.io/soarchain-testnet/libwasmvm.x86_64.so > libwasmvm.x86_64.so
sudo mv libwasmvm.x86_64.so /var/lib/libwasmvm.x86_64.so