sudo systemctl stop stafihubd

cd && rm -rf stafihub
git clone https://github.com/stafihub/stafihub.git
cd stafihub
git checkout v0.5.1
make install

sudo systemctl start stafihubd
