sudo systemctl stop palomad

cd || return
curl -# -L https://github.com/palomachain/paloma/releases/download/v0.6.1/paloma_Linux_x86_64.tar.gz > paloma_Linux_x86_64.tar.gz
sudo tar -xvzf paloma_Linux_x86_64.tar.gz palomad
sudo mv palomad /usr/local/bin
rm paloma_Linux_x86_64.tar.gz

palomad tendermint unsafe-reset-all --home $HOME/.paloma

wget -O ~/.paloma/config/genesis.json https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-7/genesis.json
wget -O ~/.paloma/config/addrbook.json https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-7/addrbook.json

sudo systemctl start palomad
