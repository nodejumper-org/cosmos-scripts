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
curl https://snapshots2.nodejumper.io/galaxy/galaxy-1_2022-11-14.tar.lz4 > snapshot.tar.lz4
lz4 -d -c snapshot.tar.lz4 | tar xf -

mv $HOME/.galaxy/priv_validator_state.json.backup $HOME/.galaxy/data/priv_validator_state.json.backup
