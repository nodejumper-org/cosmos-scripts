# create wallet
seid keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: sei1lfpde6scf7ulzvuq2suavav6cpmpy0rzxne0pw
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.sei/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
seid status 2>&1 | jq .SyncInfo.catching_up

# go to discord channel atlantic-2-faucet and paste
!faucet YOUR_WALLET_ADDRESS

# verify the balance
seid q bank balances $(seid keys show wallet -a)

## console output:
#  balances:
#  - amount: "1000000"
#    denom: usei

# create validator
sed -i 's|^mode = "full"|mode = "validator"|g' $HOME/.sei/config/config.toml
seid tx staking create-validator \
--amount=1000000usei \
--pubkey=$(seid tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=atlantic-2 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--from=wallet \
-y

# make sure you see the validator details
seid q staking validator $(seid keys show wallet --bech val -a)

# install pricefeeder
cd || return
cd sei-chain || return
make install-price-feeder
price-feeder version

mkdir -p $HOME/.price-feeder
cp $HOME/sei-chain/oracle/price-feeder/config.example.toml $HOME/.price-feeder/price-feeder.toml

seid keys add feeder-wallet --keyring-backend os
seid tx bank send wallet YOUR_FEEDER_ADDRESS 1000000usei --from wallet --chain-id atlantic-2 --fees 2000usei -y
seid q bank balances $(seid keys show feeder-wallet --keyring-backend os -a)

CHAIN_ID=atlantic-2
KEYRING_PASSWORD=YOUR_KEYRING_PASSWORD
WALLET_ADDRESS=$(seid keys show wallet -a)
FEEDER_ADDRESS=$(seid keys show feeder-wallet --keyring-backend os -a)
VALIDATOR_ADDRESS=$(seid keys show wallet --bech val -a)
GRPC="localhost:9090"
RPC="http://localhost:26657"

seid tx oracle set-feeder $FEEDER_ADDRESS  --from wallet --fees 2000usei -y

sed -i '/^dir *=.*/a pass = ""' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^address *=.*|address = "'$FEEDER_ADDRESS'"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^chain_id *=.*|chain_id = "'$CHAIN_ID'"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^validator *=.*|validator = "'$VALIDATOR_ADDRESS'"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^backend *=.*|backend = "os"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^dir *=.*|dir = "'$HOME/.sei'"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^pass *=.*|pass = "'$KEYRING_PASSWORD'"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^grpc_endpoint *=.*|grpc_endpoint = "'$GRPC'"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^tmrpc_endpoint *=.*|tmrpc_endpoint = "'$RPC'"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^global-labels *=.*|global-labels = [["chain_id", "'$CHAIN_ID'"]]|g' $HOME/.price-feeder/price-feeder.toml

sudo tee /etc/systemd/system/price-feeder.service > /dev/null << EOF
[Unit]
Description=Sei Price Feeder
After=network-online.target
[Service]
User=$USER
ExecStart=$(which price-feeder) $HOME/.price-feeder/price-feeder.toml --log-level debug
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
Environment="PRICE_FEEDER_PASS=$KEYRING_PASSWORD"
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable price-feeder
sudo systemctl start price-feeder
sudo journalctl -u price-feeder -f --no-hostname -o cat
