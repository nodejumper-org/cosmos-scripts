sudo systemctl stop galaxyd

cd || return
rm -rf galaxy
git clone https://github.com/galaxynetwork/galaxy.git
cd galaxy || return
git checkout v1.2.0
make install
galaxyd version # v1.2.0

cp $HOME/.galaxy/data/priv_validator_state.json $HOME/.galaxy/priv_validator_state.json.backup

cd $HOME/.galaxy || return
rm -rf data
wget -O snapshot.tar.gz http://95.216.72.28/data.tar.gz
tar -xf snapshot.tar.gz -C .
rm -v snapshot.tar.gz
