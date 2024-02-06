sudo systemctl stop zetacored

cd && rm -rf node
git clone https://github.com/zeta-chain/node
cd node
git checkout v12.2.1
make install

sudo systemctl start zetacored
