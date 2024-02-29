sudo systemctl stop Cardchaind

# build new binary
cd && rm -rf Cardchain
git clone https://github.com/DecentralCardGame/Cardchain
cd Cardchain
git checkout v0.14.1
cd cmd/Cardchaind
go mod download
go build
mkdir -p $HOME/go/bin
sudo mv Cardchaind "$(which Cardchaind)"

# rename home dir
mv $HOME/.Cardchain $HOME/.cardchaind

# update genesis
curl -L https://snapshots-testnet.nodejumper.io/cardchain-testnet/genesis.json > $HOME/.cardchaind/config/genesis.json

# set new chain-id
Cardchaind config chain-id cardtestnet-9

# update seeds
sed -i -e 's|^seeds *=.*|seeds = "2aa407243c982ce2d9ee607b15418cf45b5002f7@202.61.225.157:20056,947aa14a9e6722df948d46b9e3ff24dd72920257@cardchain-testnet-seed.itrocket.net:31656"|' $HOME/.cardchaind/config/config.toml

# disable state-sync
sed -i '/\[statesync\]/,/^\[.*\]/{s/enable = true/enable = false/}' $HOME/.cardchaind/config/config.toml

# reset a chain data and validator state
Cardchaind tendermint unsafe-reset-all --keep-addr-book --home $HOME/.cardchaind

sudo systemctl start Cardchaind
