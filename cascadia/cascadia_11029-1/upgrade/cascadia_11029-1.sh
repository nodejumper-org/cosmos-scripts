sudo systemctl stop cascadiad

# update chain-id
cascadiad config chain-id cascadia_11029-1

# install 0.1.9 binary
curl -L https://github.com/CascadiaFoundation/cascadia/releases/download/v0.1.9/cascadiad -o cascadiad
chmod +x cascadiad
sudo mv cascadiad /usr/local/bin

# update genesis
curl -# -L https://raw.githubusercontent.com/CascadiaFoundation/chain-configuration/master/testnet/genesis.json -o ~/.cascadiad/config/genesis.json

# update service file
sudo tee /etc/systemd/system/cascadiad.service > /dev/null << EOF
[Unit]
Description=Cascadia Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which cascadiad) start --chain-id cascadia_11029-1
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

# reset all chain data
cascadiad tendermint unsafe-reset-all --home $HOME/.cascadiad --keep-addr-book

sudo systemctl daemon-reload
sudo systemctl restart cascadiad
