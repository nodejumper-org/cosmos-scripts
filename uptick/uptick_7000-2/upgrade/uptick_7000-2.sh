sudo systemctl stop uptickd

uptickd config chain-id uptick_7000-2
uptickd tendermint unsafe-reset-all --home $HOME/.uptickd

curl https://raw.githubusercontent.com/UptickNetwork/uptick-testnet/main/uptick_7000-2/genesis.json > $HOME/.uptickd/config/genesis.json

seeds=""
peers="9ffdc3cd450758f09e1c31f2548c812a5c86f141@uptick-testnet.nodejumper.io:29656,eecdfb17919e59f36e5ae6cec2c98eeeac05c0f2@peer0.testnet.uptick.network:26656,178727600b61c055d9b594995e845ee9af08aa72@peer1.testnet.uptick.network:26656,94b63fddfc78230f51aeb7ac34b9fb86bd042a77@uptick-testnet-rpc.p2p.brocha.in:30556"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.uptickd/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.uptickd/config/app.toml
sed -i 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|g' $HOME/.uptickd/config/app.toml
sed -i 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|g' $HOME/.uptickd/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.uptickd/config/app.toml

sudo systemctl restart uptickd
sudo journalctl -u uptickd -f --no-hostname -o cat
