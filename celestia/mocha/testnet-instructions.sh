# Create VALIDATOR wallet
celestia-appd keys add wallet

## Console output
#- name: wallet
#  type: local
#  address: celestia19kmadqs9nsppn4wz5yp4rw8zn9545rc4zwvs7
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Auq9WzVEs5pCoZgr2WctjI7fU+lJCH0I3r6GC1oa0tc0"}'
#  mnemonic: ""

#!!! SAVE SEED PHRASE
kite upset hip dirt pet winter thunder slice parent flag sand express suffer chest custom pencil mother bargain remember patient other curve cancel sweet

# Create ORCHESTRATOR wallet
celestia-appd keys add orchestrator

## Console output
#  name: orchestrator
#  type: local
#- address: celestia1x5c4vj5u0wcgvdclrr6mk2ekrs7emcjpkfa3dw
#  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"Aq4dSZa+5A3SR3+dZVWkXUcHmWuZQ+Xx7Iu1KHHtnWCW"}'

#!!! SAVE SEED PHRASE
infant wasp injury parrot morning bag wet clean address pact hobby emerge raccoon rain degree dwarf gas defense deposit maximum order cross powder monitor

# Create ETH address in metamask

# Wait util the node is synced, should return FALSE
curl -s localhost:26657/status | jq .result.sync_info.catching_up

# Go to https://discord.gg/kUSueaB22b and request tokens in faucet channel for validator and orchestrator addresses

# Verify the balance
celestia-appd q bank balances $(celestia-appd keys show wallet -a)
celestia-appd q bank balances $(celestia-appd keys show orchestrator -a)

## Console output
#  balances:
#  - amount: "1000000"
#    denom: utia

# Create validator
celestia-appd tx staking create-validator \
--amount=1000000utia \
--pubkey=$(celestia-appd tendermint show-validator) \
--moniker="YOUR_VALIDATOR_MONIKER" \
--chain-id=mocha \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--from=wallet \
--evm-address="YOUR_ETH_ADDRESS" \
--orchestrator-address="YOUR_ORCHESTRATOR_ADDRESS" \
--gas=auto \
--gas-adjustment=1.5 \
--fees=1500utia \
-y

# Make sure you see the validator details
celestia-appd q staking validator $(celestia-appd keys show wallet --bech val -a)
