sudo systemctl stop terpd

cd || return
rm -rf terp-core
git clone https://github.com/terpnetwork/terp-core.git
cd terp-core || return
git checkout v0.2.0
make install
terpd version # v0.2.0

sudo systemctl restart terpd
