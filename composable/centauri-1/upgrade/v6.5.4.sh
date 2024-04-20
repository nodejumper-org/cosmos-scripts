cd && rm -rf composable-centauri
git clone https://github.com/notional-labs/composable-centauri
cd composable-centauri
git checkout v6.5.4
make install

sudo systemctl restart centaurid
