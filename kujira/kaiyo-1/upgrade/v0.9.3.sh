sudo systemctl stop kujirad

cd || return
rm -rf core
git clone https://github.com/Team-Kujira/core.git
cd core || return
git checkout v0.9.3
make install

sudo systemctl start kujirad
