sudo systemctl stop rizond

cd || return
rm -rf rizon
git clone https://github.com/rizon-world/rizon.git
cd rizon || return
git checkout v0.5.0
make install
rizond version # v0.5.0

sudo systemctl start rizond
