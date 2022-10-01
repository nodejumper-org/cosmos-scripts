sudo systemctl stop osmosisd

cd || return
rm -rf osmosis
git clone https://github.com/osmosis-labs/osmosis
cd osmosis || return
git checkout v12.0.0
make install

sudo systemctl restart osmosisd
