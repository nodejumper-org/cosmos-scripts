sudo systemctl stop pylonsd

cd || return
rm -rf pylons
git clone https://github.com/Pylons-tech/pylons
cd pylons || return
git checkout v1.1.4
make install

sudo systemctl restart pylonsd
