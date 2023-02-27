sudo systemctl stop nibid

# reset existing chain data, set new chain id
cp $HOME/.nibid/config/priv_validator_key.json $HOME/priv_validator_key.json_NIBIRU_BK
rm -rf $HOME/.nibid

# install new binaries
source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/nibiru/nibiru-itn-1/install.sh)

cp $HOME/priv_validator_key.json_NIBIRU_BK $HOME/.nibid/config/priv_validator_key.json

sudo systemctl restart nibid
