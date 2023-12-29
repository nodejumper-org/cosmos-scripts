# Download binaries
cd $HOME
wget https://github.com/InjectiveLabs/injective-chain-releases/releases/download/${tag}/linux-amd64.zip
unzip -o linux-amd64.zip
sudo mv peggo /usr/bin
sudo mv injectived /usr/bin
sudo mv libwasmvm.x86_64.so /usr/lib
rm linux-amd64.zip