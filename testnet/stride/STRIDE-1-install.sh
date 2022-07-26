#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="STRIDE-1"
CHAIN_DENOM="ustrd"
BINARY="strided"
CHEAT_SHEET="https://nodejumper.io/stride-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf stride
git clone https://github.com/Stride-Labs/stride.git
cd stride || return
git checkout c53f6c562d9d3e098aab5c27303f41ee055572cb
make build
sudo cp $HOME/stride/build/strided /usr/local/bin
strided version #

strided config chain-id $CHAIN_ID
strided init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/Stride-Labs/testnet/main/poolparty/genesis.json > $HOME/.stride/config/genesis.json
sha256sum $HOME/.stride/config/genesis.json # d6204cd1e90e74bb29e9e0637010829738fa5765869288aa29a12ed83e2847ea

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ustrd"|g' $HOME/.stride/config/app.toml
seeds="baee9ccc2496c2e3bebd54d369c3b788f9473be9@seedv1.poolparty.stridenet.co:26656"
peers="b0fb556f0f34a5802af9407801283eb1b3fb91e0@95.217.210.174:26656,95f6f66e6140db18de1dfb1f682b2efe54344ede@5.189.170.154:16656,49d41c6394c0f11b245aefd9e113c0f591bbde9d@178.18.254.164:26656,0d87189a0e88d1bd6d5c97585a3e597a1c08c013@20.40.218.61:16656,36a32b181470648cf0b925871aff96344db6a20a@188.130.160.4:26656,63977baf58a66dfb1b1a82ed6bf640ef7d50cb52@185.144.99.13:26656,b02bc17bf2e20b6c96669a45c3a92ac02d655159@104.46.232.231:26656,fef5a04c72fb967e4271d0d73cfa8a87234b0dd3@95.217.155.89:16656,127cef7528a48579184f300b5b11af49d0f53967@158.101.166.214:16656,6e043a03c502cca4782dd14c14c81414b2956b22@65.21.134.202:26616,ced9879943938e9fab678a4ff4612e234c5bc596@5.161.101.109:16656,25d470f54cfcb1a8924cd1870c8529f0673e4441@38.242.209.71:16656,8d76fe30aaaa08fe3751b826c5845af7cfea27e4@35.232.107.43:26656,0e46d5cbd0cb345b39f97141c30c48351a793ad4@51.75.135.47:16656,a1a3bd34e006db5ebb6c76389be00f31fed51329@20.14.90.246:16656,c5a1dbac090cb2f1b90e33a01ce051c80fbeb0d8@38.242.151.147:16656,476685b704aff04df7060ef0c5a3a6298dc61018@164.92.80.118:16656,50cf03c52738a1d9cf3afd1a5cf5ad25f42f44b7@65.108.79.246:26709,95ee745023b21aee6aa62c46352724b5f32240cd@161.97.91.70:16656,e1ebac39cab0856e392bdb8e37de2ff72a39107f@45.85.147.175:26656,1cc56ca0734999494c59f80742e3b6125f058718@135.181.89.127:16656,8c069ced6c1689c5680efa8f9b26df20b83bcd4d@141.147.7.244:16656,59bd2e026f6597ceba250779b991ee55fb49cfdc@51.195.145.100:26656,bfea1a928ffaaa5c8ceb5625f426a235103ef997@192.46.221.20:16656,d1eec65ab1d16ea6fa989dc8b344326f095486f8@62.171.146.12:26656,5d2f174917ddb9772c701158a367a7c701d023f8@3.16.151.253:26656,022793b3b621cb9e42145f1cca52f8fae314f8a6@95.70.160.41:26656,a3be3e353e33119318a4c1e9ff96cdf89b4c8810@130.255.170.151:36656,a586885a3c064cea689812c73c44c4d5b9d4c0eb@78.47.95.39:26656,2479c0978b634f2bab4d21608c2fc6ad9e8761c1@34.82.0.55:16656,0c3e740f1ba396b39c5761a0709142a9d894f987@35.203.110.112:16656,8e8b45efd367992874fcbe2505fb4e7360be2228@45.91.168.223:16656,137f72eecbc6193a207faafe4a38805cf758b65b@40.76.99.149:16656,b8701935431611c1b095a061c1d0fbd0ab385678@20.83.182.126:16656,70682254efa3feb147967c4b21d34db2ddac8e9f@78.47.45.36:26656,47ca3b00d259bd297b8d65f61aca0e3bcc6e7e8f@65.21.241.128:16656,b8dee7c91dbf7f5e293a078581b7a0cb0b6bd60d@23.88.66.239:46656,b96c807bfcab89fbf50c1d333701bd7ef255f7d6@65.108.58.240:16656,ad754033ac0e8dc7eb5c9af872dc2c5329a6b615@154.12.242.197:16656,a99883a25019f2ac6f4f62121ae5fa1787341ce1@185.217.126.46:16656,51320bc1f9c5621467e610299053d460f9527067@135.181.202.21:16656,69b5bde2e2b3cb3f500a32b4deb29fe2a36768ca@77.37.176.99:25656,890185f4e752b3f34a75a74a2eb9cc5e4b02afb9@109.238.12.121:16656,94c8fce4e5df0ace7a5a4e89b329f0f381378850@194.163.129.79:16656,f0144b42613fd2b4b755ce9fb3c059edd7007d8c@34.125.95.80:16656,ee61ae706c8839037ab640a5d0484ae2dfd68066@38.242.198.81:26656,f000055833b59a71b3ca10ed8526c9457872c1eb@142.93.136.117:16656,48b96f4b6e568e18c25a4392834b1c12bc356eaa@164.92.215.251:16656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.stride/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.stride/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.stride/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.stride/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.stride/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/strided.service > /dev/null << EOF
[Unit]
Description=Stride Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which strided) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

strided tendermint unsafe-reset-all --home $HOME/.stride/ --keep-addr-book

SNAP_RPC="https://stride-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.stride/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable strided
sudo systemctl restart strided

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
