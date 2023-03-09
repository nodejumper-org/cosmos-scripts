#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="qsr-questnet-04"
CHAIN_DENOM="uqsr"
BINARY_NAME="quasard"
BINARY_VERSION_TAG="0.0.2-alpha-11"
CHEAT_SHEET="https://nodejumper.io/quasar-testnet/cheat-sheet"

printLine
echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
curl -L https://github.com/quasar-finance/binary-release/raw/main/v0.0.2-alpha-11/quasarnoded-linux-amd64 > quasard
chmod +x quasard
sudo mv quasard /usr/local/bin/
quasard version # 0.0.2-alpha-11

quasard config keyring-backend test
quasard config chain-id $CHAIN_ID
quasard init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/quasar-finance/questnet/main/v04/definitive-genesis.json > $HOME/.quasarnode/config/genesis.json
curl -s https://snapshots2-testnet.nodejumper.io/quasar-testnet/addrbook.json > $HOME/.quasarnode/config/addrbook.json

SEEDS="7ed8e233e5fdb21bf70ac7f635130c7a8b0a4967@quasar-testnet-seed.swiss-staking.ch:10056"
PEERS="d5519e378247dfb61dfe90652d1fe3e2b3005a5b@65.109.68.190:48656,fdc1babb7ad4d97a911d32b0545220c8ceca57a8@128.199.8.206:53656,11d9e9d25cc78d2a0270a3d5a7e849775b110e64@185.249.225.63:48656,b1197bd0946b3d2d462fcc7548a79e87101d2389@65.108.141.109:38656,5265b02d7a5e43275f3383e6385cdc0506b99e1a@65.109.28.177:28656,3c8afd3c39b7ab28cdb801e45ea4d9249a51e22b@88.99.161.162:20656,18134130ea3156767191d89e9654b0117f54460b@43.156.246.92:26656,881db78e40385d87614cb847c2a19e8ead25b52c@43.159.47.25:26656,966acc999443bae0857604a9fce426b5e09a7409@65.108.105.48:18256,02e9ca11b64c2c6710f9642a79d576d7134ea215@43.159.54.23:26656,45848bc173bddbf7c685938dfada535ee5a1895b@65.109.23.114:18256,b122b1d76f5d676233ebbd0011c2fd7bf5960e53@43.156.10.155:26656,0bc5253d4db2af78fb7c96fa77e5f0734ea10331@43.156.61.70:26656,e339401b40f12aaf9efca323214040f51f3ff4b6@65.109.87.135:18656,d7b332b225b27a0c3338e9bce1e3ef1dd37d0c10@43.156.36.141:26656,dcf78ede935a42361895928d35119ed4789abb9c@65.109.85.225:8090,eea117634dd5e280e94e931ecf5d3f2b462bcd9d@43.156.69.134:26656,ed3bb97860ef0197a00b27127e0aaa9dd7af2817@94.130.177.114:29656,b3299d6ad3ff7452cba7d651d2c678e565fdd281@43.156.72.55:26656,afcfb038b1235a9a41128e73c4ac2bc6838b5f04@129.226.216.213:26656,9e55c6920edce61ea2a7328e437a650e8884f090@209.126.2.83:26656,fafd24c060f625a610d632a314ae916555b3d11a@43.156.98.245:26656,46ab1cfab36eeebc9b073612d69fee1c634b22d4@147.182.244.154:26656,8df102b790607051362abacf34ec671c37d096bf@43.153.203.222:26656,5271226f8a6a0f981720b7f8656cf424db0ce580@129.226.201.224:26656,f79f912153840caf703393d784b94b2e50371c61@43.156.118.199:26656,231b35d147fdd2bc9027106eeef63b448f1f404b@43.156.225.47:26656,01234fe8e5aa29abe6b5d30764f9b50ca5cdeb98@139.180.139.191:26656,c5b0e2e7ac4b16a6bd7619e9335f687028cb1d5e@43.156.137.165:26656,b5fcb5c89e5ec40188be886625acd349df52795a@43.156.137.130:26656,ecaba1301b48b32d8c97bb6a2eef6b9fb27169c0@64.176.45.149:26656,3a5480bfdf27c1b103f0257056b000175e3e1a06@176.124.220.21:26656,e2bfc397cdfd70fd731cb97d568d869b36b97456@43.153.205.74:26656,23b3f4a6d894400664f464613971da60465a4a36@43.156.120.96:26656,b26391f18fe3a4b23f478f04157072907e5df3c5@43.153.205.91:26656,b82edb8acc9f7d486de3b4fcd857d7c588d6956b@43.154.17.254:26656,a23f002bda10cb90fa441a9f2435802b35164441@38.146.3.203:18256,674166550258de01e46207e565598e856aac6f62@43.154.168.128:26656,b35f3493df8c3be232fe75ef7f4d0cb9d0f59668@65.109.70.23:18256,15b2df2c900a0d1a7625ccf9bc15e7c043a9044c@43.154.143.254:26656,bfa59196c109932786885c97ccd7df7dd434d26a@43.156.233.200:26656,7490a9690d82d43f8bcfa257cdf798e8e75a4d46@38.242.130.23:29656,e3b45f7be0b6e109d16458f79a84a434bb85430f@212.118.52.14:29656,4ad7ce03e53f0edb2a1debb2d69ff754a0cbb029@142.132.158.158:23656,7d57a0d05e0a4069cb0e7125a7da9cfd3a397880@108.166.201.96:26656,d21319cfc5fff19810ae8797b4749b50018df365@94.130.36.149:26666,955ee8d360e80a7baecc0ee3ea8afa436a7aee23@43.154.73.226:26656,089763be3736463c507427b37752a0d8d465b8c6@149.102.139.80:29656,c3c648ff7683273d85c0d8e24b823b39587e38e3@178.128.85.30:53656,08f409ee63de194847ea3da6b9c593cdb3f9692d@176.124.220.124:26656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.quasarnode/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.quasarnode/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.quasarnode/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.quasarnode/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.quasarnode/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0uqsr"|g' $HOME/.quasarnode/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.quasarnode/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/quasard.service > /dev/null << EOF
[Unit]
Description=Quasar Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which quasard) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

quasard tendermint unsafe-reset-all --home $HOME/.quasarnode --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots2-testnet.nodejumper.io/quasar-testnet/info.json | jq -r .fileName)
curl "https://snapshots2-testnet.nodejumper.io/quasar-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.quasarnode"

sudo systemctl daemon-reload
sudo systemctl enable quasard
sudo systemctl start quasard

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
