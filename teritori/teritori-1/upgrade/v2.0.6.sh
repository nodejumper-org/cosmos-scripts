sudo systemctl stop teritorid

cd && rm -rf teritori-chain
git clone https://github.com/TERITORI/teritori-chain
cd teritori-chain || return
git checkout v2.0.6
make install

sudo systemctl start teritorid
