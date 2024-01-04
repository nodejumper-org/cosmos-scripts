sudo systemctl stop cardchaind

# build new binary
cd || return
rm -rf Cardchain
git clone https://github.com/DecentralCardGame/Cardchain
cd Cardchain || return
git checkout v0.13.0
cd cmd/Cardchaind || return
go mod download
go build
mkdir -p $HOME/go/bin
sudo mv Cardchaind "$(which Cardchaind)"

# update genesis
curl -s http://45.136.28.158:3000/genesis.json > $HOME/.Cardchain/config/genesis.json

# set new chain-id
cardchaind config chain-id cardtestnet-8

# update peers
SEEDS=""
PEERS="58bb9f1dcde0408fe4c3e7f8c6ccb7f8e410ca9c@202.61.225.157:26656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.Cardchain/config/config.toml

# disable state-sync
sed -i '/\[statesync\]/,/^\[.*\]/{s/enable = true/enable = false/}' $HOME/.Cardchain/config/config.toml

# reset a chain data and validator state
cardchaind tendermint unsafe-reset-all --keep-addr-book --home $HOME/.Cardchain

sudo systemctl start cardchaind
