sudo systemctl stop dymd

cd || return
rm -rf dymension
git clone https://github.com/dymensionxyz/dymension.git
cd dymension || return
git checkout v2.0.0-alpha.5
make install

sudo systemctl start dymd
