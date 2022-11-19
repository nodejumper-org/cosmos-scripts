#!/bin/bash
# shellcheck disable=SC1090

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER
read -s -p "Enter your keyring password: " KEYRING_PASSWORD
read -s -p "Enter your tofnd password: " TOFND_PASSWORD
printf "\n"

CHAIN_ID="axelar-testnet-lisbon-3"
CHAIN_HOME=".axelar_testnet"
CHAIN_DENOM="uaxl"
AXELARD_BINARY="axelard"
AXELARD_BINARY="v0.28.0"
AXELARD_BINARY_PATH="$HOME/$CHAIN_HOME/bin/$AXELARD_BINARY"
TOFND_VERSION="v0.10.1"
CHEAT_SHEET="https://nodejumper.io/axelar-testnet/cheat-sheet"

printLine
echo -e "Node moniker:    ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:        ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain home:      ${CYAN}$CHAIN_HOME${NC}"
echo -e "Chain demon:     ${CYAN}$CHAIN_DENOM${NC}"
echo -e "axelard version: ${CYAN}$AXELARD_BINARY${NC}"
echo -e "tofnd version:   ${CYAN}$TOFND_VERSION${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

CHAIN_ID="axelar-testnet-lisbon-3"
CHAIN_HOME=".axelar_testnet"
CHAIN_DENOM="uaxl"
AXELARD_BINARY="axelard"
AXELARD_BINARY="v0.28.0"
AXELARD_BINARY_PATH="$HOME/$CHAIN_HOME/bin/$AXELARD_BINARY"
TOFND_VERSION="v0.10.1"

# create required directories
mkdir -p "$HOME/$CHAIN_HOME/"{.vald,.tofnd,bin,logs}

# build axelard binary
cd || return
rm -rf axelar-core
git clone https://github.com/axelarnetwork/axelar-core.git
cd axelar-core || return
git checkout "$AXELARD_BINARY"
make build
cp bin/axelard "$HOME/$CHAIN_HOME/bin/axelard"
make install

# download tofnd binary
curl "https://axelar-releases.s3.us-east-2.amazonaws.com/tofnd/$TOFND_VERSION/tofnd-linux-amd64-$TOFND_VERSION" > "$HOME/$CHAIN_HOME/bin/tofnd"
chmod +x "$HOME/$CHAIN_HOME/bin/tofnd"

# init chain
axelard init "$NODE_MONIKER" --chain-id $CHAIN_ID --home "$HOME/$CHAIN_HOME"

# override configs
curl https://raw.githubusercontent.com/axelarnetwork/axelarate-community/main/configuration/app.toml > "$HOME/$CHAIN_HOME/config/app.toml"
curl https://raw.githubusercontent.com/axelarnetwork/axelarate-community/main/configuration/config.toml > "$HOME/$CHAIN_HOME/config/config.toml"
curl https://raw.githubusercontent.com/axelarnetwork/axelarate-community/main/resources/testnet/seeds.toml > "$HOME/$CHAIN_HOME/config/seeds.toml"
curl https://raw.githubusercontent.com/axelarnetwork/axelarate-community/main/resources/testnet/genesis.json > "$HOME/$CHAIN_HOME/config/genesis.json"
sed -i 's|external_address = ""|external_address = "'"$(curl -4 ifconfig.co)"':26656"|g' "$HOME/$CHAIN_HOME/config/config.toml"

# check genesis sha256sum
sha256sum "$HOME/$CHAIN_HOME/config/genesis.json" # 4f53f04d62a01c247ef52558b5671e96f9fcee3b74192ef58f5cc3dd82b2f3d7

# in case of pruning
sed -i 's|^pruning *=.*|pruning = "custom"|g' "$HOME/$CHAIN_HOME/config/app.toml"
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' "$HOME/$CHAIN_HOME/config/app.toml"
sed -i 's|pruning-interval = "0"|pruning-interval = "13"|g' "$HOME/$CHAIN_HOME/config/app.toml"

printCyan "5. Starting services and synchronization..." && sleep 1

sudo tee /etc/systemd/system/axelard.service > /dev/null << EOF
[Unit]
Description=Axelard Cosmos daemon
After=network-online.target

[Service]
User=$USER
ExecStart="$AXELARD_BINARY_PATH" start --home "$HOME/$CHAIN_HOME" --moniker "$NODE_MONIKER"
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/tofnd.service > /dev/null << EOF
[Unit]
Description=Tofnd daemon
After=network-online.target

[Service]
User=$USER
ExecStart=/usr/bin/sh -c 'echo "$TOFND_PASSWORD" | "$HOME/$CHAIN_HOME/bin/tofnd" -m existing -d $HOME/$CHAIN_HOME/.tofnd'
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/vald.service > /dev/null << EOF
[Unit]
Description=Vald daemon
After=network-online.target
[Service]
User=$USER
ExecStart=/usr/bin/sh -c 'echo "$KEYRING_PASSWORD" | $AXELARD_BINARY_PATH vald-start --validator-addr \$(echo "$KEYRING_PASSWORD" | $AXELARD_BINARY_PATH keys show validator --home "$HOME/$CHAIN_HOME" --bech val -a) --log_level debug --chain-id $CHAIN_ID --from broadcaster --home "$HOME/$CHAIN_HOME"'
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# save variables
# shellcheck disable=SC2129
echo "export PATH=$PATH:$HOME/$CHAIN_HOME/bin" >> "$HOME/.bash_profile"
echo "export AXELARD_HOME=$HOME/$CHAIN_HOME" >> "$HOME/.bash_profile"
echo "export AXELARD_CHAIN_ID=$AXELARD_CHAIN_ID" >> "$HOME/.bash_profile"

# TODO: add sync section
axelard tendermint unsafe-reset-all --home "$HOME/$CHAIN_HOME"
URL=`curl -L https://quicksync.io/axelar.json | jq -r '.[] |select(.file=="axelartestnet-lisbon-3-pruned")|.url'`
cd "$HOME/$CHAIN_HOME" || return
wget -O - $URL | lz4 -d | tar -xvf -
cd $HOME || return

sudo systemctl daemon-reload
sudo systemctl enable axelard
sudo systemctl enable tofnd
sudo systemctl enable vald
sudo systemctl restart axelard
sudo systemctl restart tofnd
sudo systemctl restart vald

printLine
echo -e "Check $AXELARD_BINARY logs:    ${CYAN}sudo journalctl -u $AXELARD_BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$AXELARD_BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
