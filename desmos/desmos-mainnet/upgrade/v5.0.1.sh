sudo systemctl stop desmosd

cd || return
rm -rf desmos
git clone https://github.com/desmos-labs/desmos.git
cd desmos || return
git checkout v5.0.1
make install
desmos version # 5.0.1

sudo systemctl start desmosd
