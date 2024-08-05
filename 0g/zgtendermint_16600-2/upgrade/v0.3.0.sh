# build new binary
cd && rm -rf 0g-chain
git clone -b v0.3.0 https://github.com/0glabs/0g-chain.git
cd 0g-chain
make install

# restart chain service
sudo systemctl restart 0gchaind
