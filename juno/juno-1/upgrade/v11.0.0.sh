sudo systemctl stop junod

cd || return
rm -rf juno
git clone https://github.com/CosmosContracts/juno.git
cd juno || return
git checkout v11.0.0
make install

sudo systemctl restart junod
