cd && rm -rf node
git clone https://github.com/zeta-chain/node
cd node
git checkout v17.0.0
make install

sudo systemctl restart zetacored
