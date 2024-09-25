sudo systemctl stop terpd

cd || return
rm -rf terp-core
git clone https://github.com/terpnetwork/terp-core.git
cd terp-core || return
git checkout v3-pigeonfall
make install

sudo systemctl start terpd
