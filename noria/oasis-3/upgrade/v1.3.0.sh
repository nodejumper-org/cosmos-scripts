sudo systemctl stop noriad

cd || return
rm -rf noria
git clone https://github.com/noria-net/noria.git
cd noria || return
git checkout v1.3.0
make install
noriad version # 1.3.0

sudo systemctl start noriad
