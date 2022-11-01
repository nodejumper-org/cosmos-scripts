sudo systemctl stop evmosd

cd || return
rm -rf evmos
gir clone https://github.com/evmos/evmos.git
cd evmos || return
git checkout v9.1.0
make install

sudo systemctl restart evmosd
