sudo systemctl stop palomad
sudo systemctl stop pigeond

palomad tendermint unsafe-reset-all --home $HOME/.paloma

# upgrade paloma
curl -L https://github.com/palomachain/paloma/releases/download/v0.10.4/paloma_Linux_x86_64.tar.gz > paloma.tar.gz
tar -xvzf paloma.tar.gz
rm -rf paloma.tar.gz
sudo mv -f palomad /usr/local/bin/palomad
palomad version # v0.10.4

wget -O ~/.paloma/config/genesis.json https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-11/genesis.json
wget -O ~/.paloma/config/addrbook.json https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-11/addrbook.json

# upgrade pigeon
curl -L https://github.com/palomachain/pigeon/releases/download/v0.9.1/pigeon_Linux_x86_64.tar.gz > pigeon.tar.gz
tar -xvzf pigeon.tar.gz
rm -rf pigeon.tar.gz
sudo mv -f pigeon /usr/local/bin/pigeon
pigeon version # v0.9.1

sudo systemctl start pigeond
sudo systemctl start palomad
