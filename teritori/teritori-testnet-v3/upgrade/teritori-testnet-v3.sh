sudo systemctl stop teritorid
teritorid tendermint unsafe-reset-all --home $HOME/.teritorid --keep-addr-book

cd || return
rm -rf teritori-chain
git clone https://github.com/TERITORI/teritori-chain
cd teritori-chain || return
git checkout b412a5a1d4853382ab9abea59e1777b8e8fcc7fc
make install
teritorid version # HEAD-b412a5a1d4853382ab9abea59e1777b8e8fcc7fc

CHAIN_ID="teritori-testnet-v3"
teritorid config chain-id $CHAIN_ID

curl -L -s https://github.com/TERITORI/teritori-chain/raw/mainnet/testnet/teritori-testnet-v3/genesis.json > $HOME/.teritorid/config/genesis.json
sha256sum $HOME/.teritorid/config/genesis.json #b486346282d0b1699e28fc0fc60182c6623ae7766af459517dfac0e708d90cb7

seeds=""
peers="0d19829b0dd1fc324cfde1f7bc15860c896b7ac1@teritori-testnet.nodejumper.io:27656,ccc59b8a55f9c6e7a24bd693e2796f781ea3a670@65.108.227.133:27656,5ae1012f9b0f4672d8152de903d115dd2f1a3ee3@65.21.170.3:27656,22101a61b235e607d5d0ad51b698d7511ebf87e2@65.108.43.227:26796,15dd94f68c450da2c3b7c60b6364e3dce6f0cbf2@185.193.66.68:26641,620045eefca07f38537caf87af6b4e3a38f6214c@65.109.2.212:26656,9d709483ac8dbbe4adf19eb1b4732531254a2045@116.202.236.115:21096,6131a9f944b27bf5a7c74022289697ba3889b502@78.46.16.236:11134"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.teritorid/config/config.toml

sudo systemctl restart teritorid
sudo journalctl -u teritorid -f --no-hostname -o cat