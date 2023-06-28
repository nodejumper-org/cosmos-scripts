sudo systemctl stop okp4d

cd || return
rm -rf okp4d
git clone https://github.com/okp4/okp4d.git
cd okp4d || return
git checkout v5.0.0
make install
okp4d version # 5.0.0

sudo systemctl start okp4d
