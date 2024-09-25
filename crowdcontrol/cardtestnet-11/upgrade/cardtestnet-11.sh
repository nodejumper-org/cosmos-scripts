sudo systemctl stop Cardchaind

# build new binary
cd && rm -rf Cardchain
git clone https://github.com/DecentralCardGame/Cardchain
cd Cardchain
git checkout v0.16.0
make build
sudo cp build/Cardchaind "$(which Cardchaind)"

# update genesis
curl -L https://snapshots-testnet.nodejumper.io/cardchain-testnet/genesis.json > $HOME/.cardchaind/config/genesis.json

# set new chain-id
Cardchaind config chain-id cardtestnet-11

# reset a chain data and validator state
Cardchaind tendermint unsafe-reset-all --home $HOME/.cardchaind

# download fresh address book
curl -L https://snapshots-testnet.nodejumper.io/cardchain-testnet/addrbook.json > $HOME/.cardchaind/config/addrbook.json

sudo systemctl start Cardchaind
