sudo systemctl stop Cardchaind

Cardchain unsafe-reset-all

cd || return
curl https://get.ignite.com/DecentralCardGame/Cardchain@latest! | sudo bash
Cardchain version # latest-8103a490

curl https://raw.githubusercontent.com/DecentralCardGame/Testnet/main/genesis.json > $HOME/.Cardchain/config/genesis.json
sha256sum $HOME/.Cardchain/config/genesis.json # e13a5310f2632e80da02f5c9337d48c151d95c3b8e26bf32bfa97a1c98fe52c0

SEEDS=""
PEERS="c33a6ea0c7f82b4cc99f6f62a0e7ffdb3046a345@cardchain-testnet.nodejumper.io:30656,752cfbb39a24007f7316725e7bbc34c845e7c5f1@45.136.28.158:26658"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.Cardchain/config/config.toml

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1false| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1\"\"| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.Cardchain/config/config.toml

sudo systemctl start Cardchaind
