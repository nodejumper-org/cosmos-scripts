sudo systemctl stop rizond

cd || return
cd rizon || return
git fetch --all
git checkout v0.4.0
make install

sudo systemctl start rizond
