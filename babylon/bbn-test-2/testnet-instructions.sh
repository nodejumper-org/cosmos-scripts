# create wallet
babylond keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: bbn1d6z48lnw0g9l8ndumsy9r4cc5xw334mgatm4kx
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE (example)
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.babylond/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
babylond status 2>&1 | jq .SyncInfo.catching_up

# faucet some tokens or ask them in discord
https://faucet.testnet.babylonchain.io/

# verify the balance
babylond q bank balances $(babylond keys show wallet -a)

## console output:
#  balances:
#  - amount: "100"
#    denom: ubbn

babylond create-bls-key $(babylond keys show wallet -a)
sudo systemctl restart babylond

# create validator
babylond tx checkpointing create-validator \
--amount=10ubbn \
--pubkey=$(babylond tendermint show-validator) \
--moniker="$NODE_MONIKER" \
--details="Noderunner who is grateful to the NODEJUMPER team for their support" \
--chain-id=bbn-test-2 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=2000ubbn \
--from=wallet \
-y

# make sure you see the validator details (it might take up to 30 minutes for validator to appear because of babylon epoch interval)
babylond q staking validator $(babylond keys show wallet --bech val -a)