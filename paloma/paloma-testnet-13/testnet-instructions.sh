# create ETH/BNB/PALOMA keys
pigeon evm keys generate-new $HOME/.pigeon/keys/evm/eth-main
pigeon evm keys generate-new $HOME/.pigeon/keys/evm/bnb-main
palomad keys add wallet

## console output:
#- name: wallet
#  type: local
#  address: paloma1lfpde6scf7ulzvuq2suavav6cpmpy0rzxne0pw
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

#!!! SAVE PRIVATE VALIDATOR KEY
cat $HOME/.paloma/config/priv_validator_key.json

ETH_PASSWORD = <YOUR_ETH_PASSWORD>
BNB_PASSWORD = <YOUR_ETH_PASSWORD>
PALOMA_KEYRING_PASS = <YOUR_PALOMA_PASSWORD>

ETH_SIGNING_KEY=0x$(cat $HOME/.pigeon/keys/evm/eth-main/*  | jq -r .address | head -n 1)
BSC_SIGNING_KEY=0x$(cat $HOME/.pigeon/keys/evm/bnb-main/*  | jq -r .address | head -n 1)

# top up ETH_SIGNING_KEY with 0.1ETH, chain - ETH MAINNET (the team will top up balance automatically, every day so you won't lose your funds)
# top up BSC_SIGNING_KEY with 0.1BNB, chain - ETH MAINNET (the team will top up balance automatically, every day so you won't lose your funds)

# add pigeon configs
sudo tee $HOME/.pigeon/env.sh > /dev/null << EOF
PALOMA_KEYRING_PASS=$PALOMA_KEYRING_PASS
ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/9bYS5h99MVmaa7f0fYztaHwN31k2EBvZ
ETH_PASSWORD=$ETH_PASSWORD
ETH_SIGNING_KEY=$ETH_SIGNING_KEY
BNB_RPC_URL=https://wispy-falling-tent.bsc.discover.quiknode.pro/750bbdfab9cd076e37a35b91513b47e59ad8fc51
BNB_PASSWORD=$BNB_PASSWORD
BNB_SIGNING_KEY=$BSC_SIGNING_KEY
WALLET=wallet
EOF

# restart pigeon service to apply new configs
sudo systemctl start pigeond

# wait util the node is synced, should return FALSE
palomad status 2>&1 | jq .SyncInfo.catching_up

# go to https://faucet.palomaswap.com and paste your wallet address

# verify the balance
palomad q bank balances $(palomad keys show wallet -a)

## console output:
#  balances:
#  - amount: "10000000"
#    denom: ugrain

# create validator
palomad tx staking create-validator \
--amount=9000000ugrain \
--pubkey=$(palomad tendermint show-validator) \
--moniker="YOUR_VALIDATOR_MONIKER" \
--chain-id=paloma-testnet-13 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--fees=2000ugrain \
--from=wallet \
-y

# make sure you see the validator details
palomad q staking validator $(palomad keys show wallet --bech val -a)

# make sure you validator is signing blocks
https://paloma.explorers.guru/validators
