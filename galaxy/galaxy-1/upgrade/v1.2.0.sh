sudo systemctl stop galaxyd

cd || return
rm -rf galaxy
git clone https://github.com/galaxynetwork/galaxy.git
cd galaxy || return
git checkout v1.2.0
make install
galaxyd version # v1.2.0

sudo systemctl restart galaxyd
