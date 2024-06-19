cd && rm -rf dymension
git clone https://github.com/dymensionxyz/dymension.git
cd dymension
git checkout v2.0.0-alpha.7
make install

sudo systemctl stop dymd

# fix state before start
dymd hotfix

sudo systemctl start dymd
