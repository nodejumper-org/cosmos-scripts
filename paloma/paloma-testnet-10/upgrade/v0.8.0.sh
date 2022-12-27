sudo systemctl stop palomad

curl -L https://github.com/palomachain/paloma/releases/download/v0.8.0/paloma_Linux_x86_64.tar.gz > paloma.tar.gz
tar -xvzf paloma.tar.gz
rm -rf paloma.tar.gz
sudo mv -f palomad /usr/local/bin/palomad
palomad version # v0.8.0

palomad tendermint unsafe-reset-all --home $HOME/.paloma

wget -O ~/.paloma/config/genesis.json https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-10/genesis.json
wget -O ~/.paloma/config/addrbook.json https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-10/addrbook.json

sudo systemctl start palomad
