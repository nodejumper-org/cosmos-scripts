sudo systemctl stop ununifid

cd || return
rm -rf ununifi
git clone https://github.com/UnUniFi/chain ununifi
cd ununifi || return
git checkout v2.1.0
make install

sudo systemctl start ununifid
