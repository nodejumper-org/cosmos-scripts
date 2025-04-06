# Download binary
cd $HOME && mkdir -p go/bin/
wget https://github.com/airchains-network/junction/releases/download/${tag}/junctiond
chmod +x junctiond
mv junctiond $HOME/go/bin/
