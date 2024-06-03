cd && rm -rf rebus.core
git clone https://github.com/rebuschain/rebus.core.git
cd rebus.core
git checkout v0.5.0
make install

sudo systemctl restart rebusd
