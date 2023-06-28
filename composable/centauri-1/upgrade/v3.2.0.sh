sudo systemctl stop centaurid

cd || return
rm -rf composable-centauri
git clone https://github.com/notional-labs/composable-centauri
cd composable-centauri || return
git checkout v3.2.0
make install
centaurid version # v3.2.0

sudo systemctl stop centaurid
