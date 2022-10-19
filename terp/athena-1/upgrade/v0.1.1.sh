sudo systemctl stop terpd

cd || return
rm -rf terp-core
git clone https://github.com/terpnetwork/terp-core.git
cd terp-core || return
git checkout v0.1.1
make install
terpd version # v0.1.1

sudo systemctl restart terpd
