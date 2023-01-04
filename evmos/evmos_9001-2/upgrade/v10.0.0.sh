sudo systemctl stop evmosd

cd || return
rm -rf evmos
git clone https://github.com/evmos/evmos.git
cd evmos || return
git checkout v10.0.0
make install

sudo systemctl start evmosd
