sudo systemctl stop Cardchaind

Cardchain unsafe-reset-all

sudo rm "$(which Cardchain)"
curl -L https://github.com/DecentralCardGame/Cardchain/releases/download/v0.81/Cardchain_latest_linux_amd64.tar.gz > Cardchain_latest_linux_amd64.tar.gz
tar xzf Cardchain_latest_linux_amd64.tar.gz
chmod 775 +x Cardchaind
sudo mv Cardchaind /usr/local/bin/
rm Cardchain_latest_linux_amd64.tar.gz

Cardchain config chain-id "Testnet3"
curl https://raw.githubusercontent.com/DecentralCardGame/Testnet/main/genesis.json > $HOME/.Cardchain/config/genesis.json
sha256sum $HOME/.Cardchain/config/genesis.json # 4f189f5eb4cf7815f205a5df17e3a2365035e68cc7ce03adce4e1733e3e07822

seeds=""
peers="c33a6ea0c7f82b4cc99f6f62a0e7ffdb3046a345@cardchain-testnet.nodejumper.io:30656,56d11635447fa77163f31119945e731c55e256a4@45.136.28.158:26658"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.Cardchain/config/config.toml

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1false| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1\"\"| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.Cardchain/config/config.toml

sudo tee <<EOF >/dev/null /etc/systemd/system/Cardchaind.service
[Unit]
Description=Cardchain Daemon
After=network-online.target
[Service]
User=$USER
ExecStart=$(which Cardchaind) start
Restart=always
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

sudo systemctl restart Cardchaind
