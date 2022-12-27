sudo systemctl stop teritorid

cd || return
rm -rf teritori-chain
git clone https://github.com/TERITORI/teritori-chain
cd teritori-chain || return
git checkout v1.3.0
make install
teritorid version # v1.3.0

sudo systemctl start teritorid