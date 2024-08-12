cd && rm -rf node
git clone https://github.com/zeta-chain/node
cd node
git checkout v19.0.0
make install

sudo systemctl restart zetacored
