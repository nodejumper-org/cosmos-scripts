cd && rm -rf dymension
git clone https://github.com/dymensionxyz/dymension.git
cd dymension
git checkout v3.1.0
make install

sudo systemctl restart dymd
