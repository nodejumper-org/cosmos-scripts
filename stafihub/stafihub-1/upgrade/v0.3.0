sudo systemctl stop stafihubd

cd || return
rm -rf stafihub
git clone https://github.com/stafihub/stafihub.git
cd stafihub || return
git checkout v0.3.0
make install

sudo systemctl start stafihubd
