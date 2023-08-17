# install go 1.20.5
source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/go_install.sh) -v 1.20.5

# stop the lava service
sudo systemctl stop lavad

# backup the keys
cp $HOME/.lava/config/priv_validator_key.json $HOME/priv_validator_key.json_lava_bk
cp $HOME/.lava/config/node_key.json $HOME/node_key.json_lava_bk

# reset node state
lavad tendermint unsafe-reset-all

# download new genesis file
curl -s https://raw.githubusercontent.com/lavanet/lava-config/main/testnet-2/genesis_json/genesis.json > $HOME/.lava/config/genesis.json

# build new binary file
cd || return
rm -rf lava
git clone https://github.com/lavanet/lava
cd lava || return
git checkout v0.21.1.2
make install
lavad version

# set new configs
sed -i \
  -e 's/timeout_commit = ".*"/timeout_commit = "30s"/g' \
  -e 's/timeout_propose = ".*"/timeout_propose = "1s"/g' \
  -e 's/timeout_precommit = ".*"/timeout_precommit = "1s"/g' \
  -e 's/timeout_precommit_delta = ".*"/timeout_precommit_delta = "500ms"/g' \
  -e 's/timeout_prevote = ".*"/timeout_prevote = "1s"/g' \
  -e 's/timeout_prevote_delta = ".*"/timeout_prevote_delta = "500ms"/g' \
  -e 's/timeout_propose_delta = ".*"/timeout_propose_delta = "500ms"/g' \
  -e 's/skip_timeout_commit = ".*"/skip_timeout_commit = false/g' \
  -e 's/seeds = ".*"/seeds = "3a445bfdbe2d0c8ee82461633aa3af31bc2b4dc0@testnet2-seed-node.lavanet.xyz:26656,e593c7a9ca61f5616119d6beb5bd8ef5dd28d62d@testnet2-seed-node2.lavanet.xyz:26656"/g' \
  $HOME/.lava/config/config.toml

sed -i -e 's/broadcast-mode = ".*"/broadcast-mode = "sync"/g' $HOME/.lava/config/client.toml

lavad config chain-id lava-testnet-2

# start the node
sudo systemctl start lavad
