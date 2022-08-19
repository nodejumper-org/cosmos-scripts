sudo systemctl stop strided

strided tendermint unsafe-reset-all --home $HOME/.stride

cd || return
rm -rf stride
git clone https://github.com/Stride-Labs/stride.git
cd stride || return
git checkout cf4e7f2d4ffe2002997428dbb1c530614b85df1b
make build
mkdir -p $HOME/go/bin
sudo cp $HOME/stride/build/strided $HOME/go/bin
strided version #v0.3.1

rm $HOME/.stride/config/genesis.json
strided config chain-id STRIDE-TESTNET-4

curl -s https://raw.githubusercontent.com/Stride-Labs/testnet/main/poolparty/genesis.json > $HOME/.stride/config/genesis.json
sha256sum $HOME/.stride/config/genesis.json # a1f56de30c4f88de2fe2fbff1a019583bfc57e9c2c297294ce2c7ec243e46a4e

seeds="d2ec8f968e7977311965c1dbef21647369327a29@seedv2.poolparty.stridenet.co:26656"
peers=""
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.stride/config/config.toml

sudo systemctl restart strided
