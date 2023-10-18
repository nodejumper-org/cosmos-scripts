sudo systemctl stop dymd

# reset existing chain data, set new chain id
dymd tendermint unsafe-reset-all --home $HOME/.dymension
dymd config chain-id froopyland_100-1

# build new binary
cd || return
rm -rf dymension
git clone https://github.com/dymensionxyz/dymension.git
cd dymension || return
git checkout v1.0.2-beta
make install
dymd version # v1.0.2-beta

# update genesis and address book
curl -s https://raw.githubusercontent.com/dymensionxyz/testnets/main/dymension-hub/froopyland/genesis.json > $HOME/.dymension/config/genesis.json
curl -s https://snapshots-testnet.nodejumper.io/dymension-testnet/addrbook.json > $HOME/.dymension/config/addrbook.json

# update seeds
SEEDS="ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:20556,92308bad858b8886e102009bbb45994d57af44e7@rpc-t.dymension.nodestake.top:666,284313184f63d9f06b218a67a0e2de126b64258d@seeds.silknodes.io:26157"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.dymension/config/config.toml

rm -rf $HOME/.dymension/data

# synchronize using snapshot
SNAP_NAME=$(curl -s https://snapshots-testnet.nodejumper.io/dymension-testnet/info.json | jq -r .fileName)
curl "https://snapshots-testnet.nodejumper.io/dymension-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.dymension"

sudo systemctl start dymd
