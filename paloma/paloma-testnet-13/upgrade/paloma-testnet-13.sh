sudo systemctl stop pigeond
sudo systemctl stop palomad

wget -O - https://github.com/palomachain/paloma/releases/download/v0.11.3/paloma_Linux_x86_64.tar.gz |
sudo tar -C /usr/local/bin -xvzf - palomad

wget -O - https://github.com/palomachain/pigeon/releases/download/v0.11.0/pigeon_Linux_x86_64.tar.gz |
sudo tar -C /usr/local/bin -xvzf - pigeon

palomad version # v0.11.3
pigeon version # v0.11.0

palomad config chain-id paloma-testnet-13
nano $HOME/.pigeon/config.yaml
# paloma:
#   chain-id: paloma-testnet-13

palomad tendermint unsafe-reset-all --home $HOME/.paloma

wget -O $HOME/.paloma/config/genesis.json https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-13/genesis.json
wget -O $HOME/.paloma/config/addrbook.json https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-13/addrbook.json

sudo systemctl restart pigeond
sudo systemctl restart palomad

sudo journalctl -u pigeond -f --no-hostname -o cat
