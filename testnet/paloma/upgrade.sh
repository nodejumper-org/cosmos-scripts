sudo systemctl stop palomad
curl -L https://github.com/palomachain/paloma/releases/download/v0.4.1-alpha/paloma_0.4.1-alpha_Linux_x86_64.tar.gz | sudo tar -C /usr/local/bin -xvzf - palomad
curl -s https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-6/genesis.json > $HOME/.paloma/config/genesis.json
curl -s https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-6/addrbook.json > $HOME/.paloma/config/addrbook.json

palomad tendermint unsafe-reset-all --home $HOME/.paloma

peers="ae6eaae5fb773948281b65eca4ec031a40e42b17@50.116.15.176:26656,8912f06b337b9f773225bd59e5a139e5af7eb852@65.108.235.107:10656,abc044647c4906472ca3564c5b30c6cede44e9d1@23.88.77.188:20003,b1d4dd40ea8aeb01443e92d941a719ccd7a2f4b5@130.185.118.165:10656,2d81fe626fcbeb39baa7f0e5f80ce397c87b2ee1@185.144.99.227:26656,b522201fa15b07ee3b503e853fe90cb44cf56a3c@168.119.229.69:26656,1cf04bee1fbf28f6a6a3da3d1aa13f89d0d4c296@185.244.181.27:26656"
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.paloma/config/config.toml

sudo systemctl restart palomad
sudo journalctl -u palomad -f --no-hostname -o cat
