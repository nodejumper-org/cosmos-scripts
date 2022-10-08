sudo systemctl stop pigeond
sudo systemctl stop palomad

wget -O - https://github.com/palomachain/paloma/releases/download/v0.10.4/paloma_Linux_x86_64.tar.gz |
sudo tar -C /usr/local/bin -xvzf - palomad

wget -O - https://github.com/palomachain/pigeon/releases/download/v0.9.1/pigeon_Linux_x86_64.tar.gz |
sudo tar -C /usr/local/bin -xvzf - pigeon

palomad config chain-id paloma-testnet-12
nano $HOME/.pigeon/config.yaml
# paloma:
#   chain-id: paloma-testnet-12

palomad tendermint unsafe-reset-all --home $HOME/.paloma

wget -O $HOME/.paloma/config/genesis.json https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-12/genesis.json
wget -O $HOME/.paloma/config/addrbook.json https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-12/addrbook.json

sudo systemctl restart pigeond
sudo systemctl restart palomad

sudo journalctl -u pigeond -f --no-hostname -o cat
sudo journalctl -u palomad -f --no-hostname -o cat
