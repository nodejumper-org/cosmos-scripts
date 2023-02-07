sudo systemctl stop pigeond
sudo systemctl stop palomad

wget -O - https://github.com/palomachain/paloma/releases/download/v0.11.6/paloma_Linux_x86_64.tar.gz |
sudo tar -C /usr/local/bin -xvzf - palomad

wget -O - https://github.com/palomachain/pigeon/releases/download/v0.11.5/pigeon_Linux_x86_64.tar.gz |
sudo tar -C /usr/local/bin -xvzf - pigeon

palomad version # v0.11.6
pigeon version # v0.11.5

palomad config chain-id paloma-testnet-15
nano $HOME/.pigeon/config.yaml
# paloma:
#   chain-id: paloma-testnet-15

palomad tendermint unsafe-reset-all --home $HOME/.paloma

wget -O $HOME/.paloma/config/genesis.json https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-15/genesis.json
wget -O $HOME/.paloma/config/addrbook.json https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-15/addrbook.json

SNAP_NAME=$(curl -s https://snapshots-testnet.nodejumper.io/paloma-testnet/ | egrep -o ">paloma-testnet-15.*\.tar.lz4" | tr -d ">")
curl https://snapshots-testnet.nodejumper.io/paloma-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf - -C $HOME/.paloma

sudo systemctl start pigeond
sudo systemctl start palomad

sudo journalctl -u pigeond -f --no-hostname -o cat
