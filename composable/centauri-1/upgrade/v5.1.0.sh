sudo systemctl stop centaurid

cd || return
rm -rf composable-centauri
git clone https://github.com/notional-labs/composable-centauri
cd composable-centauri || return
git checkout v5.1.0
make install

sudo systemctl start centaurid
