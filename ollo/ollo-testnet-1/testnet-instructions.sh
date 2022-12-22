# create wallet
ollod keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: ollo1lfpde6scf7ulzvuq2suavav6cpmpy0rzxne0pw
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.ollo/config/priv_validator_key.json

# wait util the node is synced, should return FALSE
ollod status 2>&1 | jq .SyncInfo.catching_up

# go to discord channel #testnet-faucet and paste
!request YOUR_WALLET_ADDRESS

# verify the balance
ollod q bank balances $(ollod keys show wallet -a)

## console output:
#  balances:
#  - amount: "50000000"
#    denom: utollo

# create validator
ollod tx staking create-validator \
--amount=49000000utollo \
--pubkey=$(ollod tendermint show-validator) \
--moniker="YOUR_VALIDATOR_MONIKER" \
--chain-id=ollo-testnet-1 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=2000utollo \
--from=wallet \
-y

# make sure you see the validator details
ollod q staking validator $(ollod keys show wallet --bech val -a)
