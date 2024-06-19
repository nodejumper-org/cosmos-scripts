cd && rm -rf dymension
git clone https://github.com/dymensionxyz/dymension.git
cd dymension
git checkout v2.0.0-alpha.8
make install

sudo systemctl restart dymd
