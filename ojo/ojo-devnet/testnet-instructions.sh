# create wallet
ojod keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: ojo1ela8c0jhqgjsj2cq7twu9uhda2n8e6cs8ztxs3
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.ojo/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
ojod status 2>&1 | jq .SyncInfo.catching_up

# Request tokens in discord

# verify the balance
ojod q bank balances $(ojod keys show wallet -a)

## console output:
#  balances:
#  - amount: "10000000"
#    denom: uojo

# create validator
ojod tx staking create-validator \
--amount=9000000uojo \
--pubkey=$(ojod tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--chain-id=ojo-devnet \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=2000uojo \
--from=wallet \
-y

# make sure you see the validator details
ojod q staking validator $(ojod keys show wallet --bech val -a)

# install pricefeeder
cd || return
rm -rf price-feeder
git clone https://github.com/ojo-network/price-feeder
cd price-feeder || return
git checkout v0.1.1
make install
price-feeder version # version: HEAD-5d46ed438d33d7904c0d947ebc6a3dd48ce0de59

mkdir -p $HOME/.price-feeder
curl -s https://raw.githubusercontent.com/ojo-network/price-feeder/main/price-feeder.example.toml > $HOME/.price-feeder/price-feeder.toml

ojod keys add feeder-wallet --keyring-backend os
ojod tx bank send wallet YOUR_FEEDER_ADDRESS 10000000uojo --from wallet --chain-id ojo-devnet --fees 2000uojo -y
ojod q bank balances $(ojod keys show feeder-wallet --keyring-backend os -a)

CHAIN_ID=ojo-devnet
KEYRING_PASSWORD=YOUR_KEYRING_PASSWORD
WALLET_ADDRESS=$(ojod keys show wallet -a)
FEEDER_ADDRESS=$(ojod keys show feeder-wallet --keyring-backend os -a)
VALIDATOR_ADDRESS=$(ojod keys show wallet --bech val -a)
GRPC="localhost:9090"
RPC="http://localhost:26657"

ojod tx oracle delegate-feed-consent $WALLET_ADDRESS $FEEDER_ADDRESS --from wallet --fees 2000uojo -y
ojod q oracle feeder-delegation $VALIDATOR_ADDRESS

sed -i '/^dir *=.*/a pass = ""' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^address *=.*|address = "'$FEEDER_ADDRESS'"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^chain_id *=.*|chain_id = "'$CHAIN_ID'"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^validator *=.*|validator = "'$VALIDATOR_ADDRESS'"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^backend *=.*|backend = "os"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^dir *=.*|dir = "'$HOME/.ojo'"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^pass *=.*|pass = "'$KEYRING_PASSWORD'"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^grpc_endpoint *=.*|grpc_endpoint = "'$GRPC'"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^tmrpc_endpoint *=.*|tmrpc_endpoint = "'$RPC'"|g' $HOME/.price-feeder/price-feeder.toml
sed -i 's|^global-labels *=.*|global-labels = [["chain_id", "'$CHAIN_ID'"]]|g' $HOME/.price-feeder/price-feeder.toml

sudo tee /etc/systemd/system/price-feeder.service > /dev/null << EOF
[Unit]
Description=Ojo Price Feeder
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
