sudo systemctl stop zetacored

cd && rm -rf node
git clone https://github.com/zeta-chain/node
cd node
git checkout v14.0.0
make install

sudo systemctl start zetacored
