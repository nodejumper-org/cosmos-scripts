sudo systemctl stop 0gchaind

# build new binary
cd && rm -rf 0g-chain
git clone -b v0.2.3 https://github.com/0glabs/0g-chain.git
cd 0g-chain
make install

# update chain-id
0gchaind config chain-id zgtendermint_16600-2

# download new genesis and addrbook
curl -L https://snapshots-testnet.nodejumper.io/0g-testnet/genesis.json > $HOME/.0gchain/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/0g-testnet/addrbook.json > $HOME/.0gchain/config/addrbook.json

# set new seeds
sed -i -e 's|^seeds *=.*|seeds = "81987895a11f6689ada254c6b57932ab7ed909b6@54.241.167.190:26656,010fb4de28667725a4fef26cdc7f9452cc34b16d@54.176.175.48:26656,e9b4bc203197b62cc7e6a80a64742e752f4210d5@54.193.250.204:26656,68b9145889e7576b652ca68d985826abd46ad660@18.166.164.232:26656"|' $HOME/.0gchain/config/config.toml

# reset chain data
0gchaind tendermint unsafe-reset-all --keep-addr-book

# start
sudo systemctl restart 0gchaind && sudo journalctl -u 0gchaind -f
