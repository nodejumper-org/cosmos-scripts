sudo systemctl stop terpd

cd || return
rm -rf terp-core
git clone https://github.com/terpnetwork/terp-core.git
cd terp-core || return
git checkout v1.0.1
make install
terpd version # 1.0.1

sudo systemctl start terpd
