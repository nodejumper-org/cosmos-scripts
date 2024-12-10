sudo systemctl stop firmachaind

cd && rm -rf firmachain
git clone https://github.com/firmachain/firmachain
cd firmachain
git checkout v0.4.0
make install

sudo systemctl start firmachaind
