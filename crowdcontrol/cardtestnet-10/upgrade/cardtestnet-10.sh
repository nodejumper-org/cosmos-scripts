sudo systemctl stop Cardchaind

# build new binary
cd && rm -rf Cardchain
git clone https://github.com/DecentralCardGame/Cardchain
cd Cardchain
git checkout v0.14.2
cd cmd/Cardchaind
go mod download
go build
mkdir -p $HOME/go/bin
sudo mv Cardchaind "$(which Cardchaind)"

# update genesis
curl -L https://snapshots-testnet.nodejumper.io/cardchain-testnet/genesis.json > $HOME/.cardchaind/config/genesis.json

# set new chain-id
Cardchaind config chain-id cardtestnet-10

# update seeds
sed -i -e 's|^seeds *=.*|seeds = ""|' $HOME/.cardchaind/config/config.toml
sed -i -e 's|^persistent_peers *=.*|persistent_peers = "ab88b326851e26cf96d1e4634d08ca0b8d812032@202.61.225.157:20056"|' $HOME/.cardchaind/config/config.toml


# reset a chain data and validator state
Cardchaind tendermint unsafe-reset-all --home $HOME/.cardchaind

# download fresh address book
curl -L https://snapshots-testnet.nodejumper.io/cardchain-testnet/addrbook.json > $HOME/.cardchaind/config/addrbook.json

sudo systemctl start Cardchaind
