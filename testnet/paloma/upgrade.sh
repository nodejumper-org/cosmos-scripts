sudo systemctl stop palomad
curl -L -# https://github.com/palomachain/paloma/releases/download/v0.4.0-alpha/paloma_0.4.0-alpha_Linux_x86_64.tar.gz | sudo tar -C /usr/local/bin -xvzf - palomad
curl -s https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-6/genesis.json > $HOME/.paloma/config/genesis.json
curl -s https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-6/addrbook.json > $HOME/.paloma/config/addrbook.json

palomad tendermint unsafe-reset-all --home $HOME/.paloma

peers="484e0d3cc02ba868d4ad68ec44caf89dd14d1845@paloma-testnet.nodejumper.io:33656,8fab1d100d1c01de299788758d31d36c321c23b5@144.202.103.140:26656,8fab1d100d1c01de299788758d31d36c321c23b5@144.202.103.140:26656,1f74adfbfa794a53b104368fcb1189eddc18d66f@173.255.229.106:26656"
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.paloma/config/config.toml

sudo systemctl restart palomad
sudo journalctl -u palomad -f --no-hostname -o cat
