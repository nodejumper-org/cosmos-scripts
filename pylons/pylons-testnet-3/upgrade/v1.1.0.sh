sudo systemctl stop pylonsd

cd || return
rm -rf pylons
git clone https://github.com/Pylons-tech/pylons
cd pylons || return
git checkout v1.1.0
make install
pylonsd version # 1.1.0

sudo systemctl start pylonsd
