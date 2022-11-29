#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="STRIDE-TESTNET-2"
CHAIN_DENOM="ustrd"
BINARY="strided"
CHEAT_SHEET="https://nodejumper.io/stride-testnet/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf stride
git clone https://github.com/Stride-Labs/stride.git
cd stride || return
git checkout 4ec1b0ca818561cef04f8e6df84069b14399590e
make build
mkdir -p $HOME/go/bin
sudo cp $HOME/stride/build/strided $HOME/go/bin
strided version #v0.3.1

strided config keyring-backend test
strided config chain-id $CHAIN_ID
strided init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/Stride-Labs/testnet/main/poolparty/genesis.json > $HOME/.stride/config/genesis.json
sha256sum $HOME/.stride/config/genesis.json # d6204cd1e90e74bb29e9e0637010829738fa5765869288aa29a12ed83e2847ea

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ustrd"|g' $HOME/.stride/config/app.toml
seeds="c0b278cbfb15674e1949e7e5ae51627cb2a2d0a9@seedv2.poolparty.stridenet.co:26656"
peers="17b24705533d633cb3501233a18912ae6cc36a41@stride-testnet.nodejumper.io:28656,fcdda87767645df851c5405d9bb8601330a469c6@51.75.135.46:16656,4a6793b026dfdeacc00648d68b865d81675c8516@65.108.124.172:28656,efb44e5336800b589053a13f2ee94d3d1cfe19d8@65.108.62.95:16656,d7d31e3477936e1ee2788f35604f8ff89a4d50ad@65.108.204.119:27656,943accf7e80f57834e57102bf342c3126138d25d@167.235.230.67:16656,f8c86373aeabc7908d3b24fa75d9c5ca38c5b345@143.244.189.163:16656,6b0775bcff26a3c4aebf9e1eeca243bd226f82e7@185.202.223.85:16656,88a34fcd6d7162e3f6063b3d618e496d6975c442@206.189.5.203:26656,f2d042a8887b76e15f913f8ff3617582a4c6f1d9@20.14.93.96:16656,8beff4429270515714b612425a99ea90423988d9@144.91.89.149:26656,5fdde3349b969ffc0095119d8ec438e6ff337804@65.109.0.10:16656,a061c212f279736c04cb553357f3867ab25ed21e@62.171.173.206:16656,35524a926fb5a57640e6a27dfae371d2be8f2daf@113.30.191.2:16656,1eabaeaaf37cc311a5e58054c838f604f03cd475@65.21.138.123:31656,b50d2f32008b12c10025e3f71f3f979451af2128@185.216.75.144:16656,17c73dfb24e3b1626a5906906cb7bfc7de141114@75.119.142.13:16656,9b7b00511ec126d88d8f79b9ee437bdff714c966@192.145.37.228:26656,fdcbb0a1d58e4bb934606abaa0e7eb9fc8ef3227@159.223.231.90:16656,4a48ddab8cabecd19427a3959484737a7e9e7bac@194.146.38.83:16656,1310dcdaac07d4427a48d17be58a4caa4905a5cb@188.166.72.156:16656,e26134d7d3e84c7a1129870d00060a03e68bb2a6@85.173.112.154:46656,b01bfd2272e0683501bd748f9291ee81d74e242f@159.65.51.99:16656,14d91d597eb59c948d8eb4a1803f5e11011cb1f0@185.167.98.119:16656,d7085dc8e59bea405409bdf138f9fdd3cedba4ec@161.97.78.233:16656,10fe01afc27fea33c7d1357ff92b26111707630c@149.102.137.255:16656,d6d45352df7a280225ff4a7e1d43659090ee85ef@49.12.214.194:16656,b2a1d723ce66f618d06a8af5e016e2b7ec4c5454@20.243.200.9:16656,2c6dc6e8a4d4158643e2ec2abec1a4305c22bd86@20.25.184.102:16656,b133d1b7978f3a3bd4de8f24e89e38a9457649f0@143.110.216.17:26656,0451f89d285424752fe6decf8f26e7468492fb9a@135.181.98.172:16656,8976de5497cfa57610861c5ade6de732c9df8069@195.54.41.122:21656,578b15b69001fca310ca5bdccad0d8d76edcabb1@65.21.146.215:16656,bd40d048dd732289c030afe1694e4b159514bc48@65.109.8.48:16656,837d7012de307462cd68c92752680abba0cbff3a@172.104.232.210:16656,1086dffd75cb3091471d605956c625c04579297b@149.102.128.86:16656,74102803e23ffe7d042f25eeb3c85004cee4929a@62.113.112.235:16656,650d124d4d4ebb64971488f3f64d3bd63368d20e@38.242.242.193:28656,38b1f2aba2e4e2a8d44a714f050e796d25123a0f@2.58.82.107:16656,f7e240ea5722083f8dcbcbf33f3d8246257c6b11@185.202.223.124:16656,6519a390620db079117a42bb4de627073f693883@109.107.191.245:26656,1db799c536fa99d40b7b497c29df8f44834a8a1d@194.5.152.107:26656,b1b9e8e68ed34ecf7556ffc90f1ccd4076dc99b6@185.202.223.58:16656,8071611b00cacb8d6a71c1916b9045f70fc3b0ca@135.181.202.21:16656,a2d09d89b81dfbca692f5c56c4f8fa1334dec5aa@5.161.84.1:12656,bda433a00b024e9407664e63209441bf8a583f6d@149.102.131.134:16656,f9d062d26ca94662c9c63138836b5c158123e015@65.21.156.50:16656,1a873c429f87010654e34ccc74d7b487fb9d2c2e@139.162.58.187:16656,ec76b749d347407c1451c26088fca2ccca269344@20.127.193.191:16656,806098a55f676f8cc591e661d854e1e20c862538@45.151.123.97:16656,bf57701e5e8a19c40a5135405d6757e5f0f9e6a3@143.244.186.222:16656,7ae3b00c50b17ec306db84155665bf7c598251d2@178.18.240.171:26656,1600b794c3727e5848efa593e16339789bad6320@116.203.41.7:16656,e6ce776d70ce7fa0797549c37ebfc45b7833ea99@194.163.159.100:16656,2d145db8d1210ee4b30717cfee56a4bb90663730@80.190.129.50:26656,2c324736ba6f7dfef00f7f0aa355514d3ccdf4dc@185.245.183.106:16656,a297064247cac26d46f02204cec8b2f395867e7b@45.91.168.238:26656,acc291258810e829db87a8babfa22cf82e217caa@141.147.7.113:26656,831adfd1e4b9b5bae0598422064508f809478156@192.145.37.4:16656,4a549dccd2b3b6805a80573ae4339c8482093744@45.94.58.107:16656,2d94446454cd1423b365e776052be11e5531ae8c@154.53.59.87:16656,6ccbf9501ddb85061ee01b96f5576f6064bd66de@146.190.52.217:16656,17b5b83f56c6659038c00964da1696b509905103@20.125.149.184:16656,4cead31d5bd4f4d89d585a49e951e9937abc2074@95.216.197.192:26656,15ce4c9786a1369e7d88b086470d973c8af644c9@159.65.202.117:16656,d5ab0580725089d2517ba1884c825af7e3b0c110@86.48.2.10:26656,afa8499cdca063885e13869c5dc871d2e79657a6@20.224.66.164:26656,a9068288df41a2ec61154d4eba0a3006cafdd7f1@159.65.86.73:16656,62853c1b7216c2d741dbe7ddaca3a8e66af6ee19@51.13.80.45:16656,f871774836f2b5792d8795b97799bb14c4364510@65.109.24.222:26656,867d83ac0bd55ef265b89fc2e4ee35e3e9daaed0@194.163.167.174:26656,58fc29e1de5a2eee8974fcc4cc1b0ba33ed84b73@138.68.93.181:16656,ff701057233627a26780da214c14a66d932eef51@192.145.37.211:26656,08d4957228eec1e165d6cbf65ef9759eada7d9f1@65.108.132.239:26657,8c08e9e09d902d3e315a4fb645d9802f5d1ea525@66.94.123.169:16656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.stride/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.stride/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.stride/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.stride/config/app.toml
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
