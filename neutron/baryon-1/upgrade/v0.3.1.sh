sudo systemctl stop neutrond

cd || return
rm -rf neutron
git clone https://github.com/neutron-org/neutron.git
cd neutron || return
git checkout v0.3.1
make install
neutrond version # v0.3.1

sudo systemctl start neutrond
