sudo systemctl stop palomad
sudo systemctl stop pigeond

# upgrade paloma
curl -L https://github.com/palomachain/paloma/releases/download/v0.11.1/paloma_Linux_x86_64.tar.gz > paloma.tar.gz
tar -xvzf paloma.tar.gz
rm -rf paloma.tar.gz
sudo mv -f palomad /usr/local/bin/palomad
palomad version # v0.11.1

# upgrade pigeon
curl -L https://github.com/palomachain/pigeon/releases/download/v0.11.0/pigeon_Linux_x86_64.tar.gz > pigeon.tar.gz
tar -xvzf pigeon.tar.gz
rm -rf pigeon.tar.gz
sudo mv -f pigeon /usr/local/bin/pigeon
pigeon version # v0.11.0

# make sure to add new tx-type entries
nano ~/.pigeon/config.yaml

#evm:
#  eth-main:
#    tx-type: 2
#  bnb-main:
#    tx-type: 0

sudo systemctl start palomad
sudo systemctl start pigeond
