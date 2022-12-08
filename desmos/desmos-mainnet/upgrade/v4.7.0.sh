sudo systemctl stop desmosd

cd || return
rm -rf desmos
git clone https://github.com/desmos-labs/desmos.git
cd desmos || return
git checkout v4.7.0
make install
desmos version # 4.7.0

sudo systemctl restart desmosd
