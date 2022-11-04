#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="evmos_9001-2"
CHAIN_DENOM="aevmos"
BINARY="evmosd"
CHEAT_SHEET="https://nodejumper.io/evmos/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1
cd || return
rm -rf evmos
git clone https://github.com/tharsis/evmos
cd evmos || return
git checkout v9.1.0
make install
evmosd version # 9.1.0

evmosd config chain-id $CHAIN_ID
evmosd init $NODE_MONIKER --chain-id $CHAIN_ID

curl https://archive.evmos.org/mainnet/genesis.json > $HOME/.evmosd/config/genesis.json
sha256sum $HOME/.evmosd/config/genesis.json # 4aa13da5eb4b9705ae8a7c3e09d1c36b92d08247dad2a6ed1844d031fcfe296c

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001aevmos"|g' $HOME/.evmosd/config/app.toml
seeds=""
peers="ab90584c1721fce720052c0b071875693cf052b4@evmos.nodejumper.io:29656,3622f96487d4d36b8d6404a64677d3086972ceac@85.237.193.90:26656,c7589a3d0be2b6324f4fb55785500e7e20aae977@65.21.200.142:13456,eba108332e888a15d770f52bacefc71cf4b87da1@34.88.224.168:26656,3838eed917034133a8b7c4b0ef493bccae6a1532@135.181.215.115:26656,8a733fd26f3ff1974cc2eb72a57f6c344da8d026@15.204.196.180:26656,8d83801176e756ca14e7eb53d0a0f1e2902e1224@116.202.129.175:26656,6f888aa6e96948232b50dcfba5d3afd74fc79379@23.88.69.22:26876,69696b704be0ff2ebd244412aba334177a51b683@141.94.242.36:36656,22e06175a263884104844cbc964c396e5f60d61e@66.45.236.82:26661,3662ee5fc3759c2ed67e7bf386d8a03377eb46b8@95.214.55.67:26656,cf6b8f0ce650a1ad8dd2a18a3f610410b23fd9d2@138.201.85.176:26666,944f85c7fd7540124c6cff0496e0805010b141db@5.9.102.204:36656,7cb741da246b987be99ddd44bfcf390d4279f59b@65.108.192.173:26656,3cc2911635c6665e5c4bce32424911e29029be37@46.4.119.90:36656,f842ac52c071d6aaf333231a5901e19d50610526@20.238.81.178:26656,850a5c8af7e21d196fb6e12b063292ca053a8594@65.21.72.115:26656,0c260e3652258bdfa3743ff54ee7eb33d1627a37@144.76.24.81:26656,e6d50114b6646418e3042951f399c128056767af@157.90.179.182:26256,3ae9e5509256e77da0a27daf0d86ae450e1f089e@15.235.51.191:11956,5c8263087112f5e0736ddb5373a80f669ac0c1fe@65.108.235.112:26656,65e1b25f46ebb1a42b80d4bd875e2f326f87c12d@95.217.88.61:27656,f990583827186834964525881bec472c01e5fd33@[2a01:4f9:6b:476d::2]:62656,8a210f1bcfc9015a7bc18dcc5add29c0dce3f2dc@95.217.70.60:26656,c461a3e8213498bf5b560cd94d94ec45f990b462@65.108.75.202:27656,e30795f965a7e622b1207618e5bafbb6aa385b50@136.243.199.113:26656,ddc9c72a9c1beb6832c52951f86138a269b31eb7@185.150.189.146:26656,4881e7757e9b39a3498ebb73c90b305350692226@18.215.126.6:26656,ba3e9af6380e71521aa5d1c7561bc8f9457ab275@204.16.244.120:26656,3ce01cd2b6f8143aea73f073e4c3afa1d5a591ef@44.211.224.197:26656,26a4ffcf2a710beb1e8840a92219d9207ab8c02b@34.138.38.130:26656,2b3ac9e4652b91c50f893920394e18e0dd34b8cd@204.16.244.107:26656,7f06ec15a94c2b0f99b4f74331e2fcae51c20a1c@69.46.15.82:26656,e48731a1434907e26c67cf9e131fbdd449436855@15.235.165.62:26656,50030b4e05c7cb00104e57550bb2fd22173c6d20@167.235.2.68:4020,1bf1d58b0c301badfdad70ccd136e33d43b5237c@65.21.192.108:4020,7323686f7146a4e858db0d582dcbe050d7469d71@142.132.197.103:16656,94b63fddfc78230f51aeb7ac34b9fb86bd042a77@176.9.98.24:30517,2ad30556c7d1455e8aff9a82d245488f346aeb05@50.21.167.171:26656,746d5a0040ef1ae5843f5bb74dd9c64e2ce6a726@52.207.212.98:26656,bcd6384b61e199382e8dd0feadf689dc6aca3890@18.204.44.9:26656,d63c1fdc70c6b8672a40c6c98cf67526f69543b6@3.232.55.100:26656,43730f5c0d348d566f0aef15ed32660123f98b14@35.245.211.8:26656,3ec864583beb0a089fc60318d5928672afb97b7e@35.227.105.39:26656,f201e6bd9f86d248a4b83cbe672010eafffdac1c@66.172.36.133:21656,a0387cc9dfa67285662882842da75921fb4c8370@67.209.54.158:26656,46821aa06600a0956c97a7aedbc3a929fd2d698c@122.10.159.26:26636,7a7daff7d2219a611c8c521b9684bda47f312dc4@35.210.149.103:26656,2670adff1db5f233bd4984fa03943969bbf5aac7@34.94.230.230:26656,af62bbb6888e6812ea2053347ff8065176d973c5@157.230.61.72:26656,1b6ca90ac2684b8e5215fad0e57c800104c38b55@44.204.119.140:26656,99e2b03b343ac604368bb2094693cde86652ba60@204.16.244.233:26656,992bb92318a7e2cea003d602ef436094b977fecc@142.132.198.47:26656,617c72274d28bf0c4ef56a399261227e389ab09f@161.97.130.97:17369,d3620b3809f5901ce6690bdbc3790ea474030c77@138.201.32.103:27656,384cd06ac005a2162e8a41e28eeaa5ef00467c1b@15.204.197.68:26656,717c7a08cda6b3962921f5230c093a6fec61ddbb@147.135.65.173:26656,3bde211c037664fdffce2d03cf8d4325ef3d7c5e@65.108.231.60:26656,544fb1b497252dec36f3f96b01ebc861e2849f0d@142.132.202.50:26656,56c4405dc2f2c6dfa0c42ce3a648160bba3d0704@35.177.241.169:26656,2075008df4b06770c1a7321f017e887845914751@35.215.34.1:26656,5b03fb91d5373312d845575671c7bd2d86593f5f@65.109.35.90:27656,819c771de763faba18aee06b6b724f11dec4f95d@18.206.118.36:26656,d201bac976e3f72dabf17718ec3f9786497bc273@141.95.85.195:26656,97e4468ac589eac505a800411c635b14511a61bb@5.9.239.236:26656,a6738f7a430c477062958bfd80ff4da000943504@107.23.86.243:26656,8a5288b84f8a3b70215609da5e3b2da28c3886da@45.132.244.177:2000,8a0efdef498a056be4e2f0b72446276306c3a2cd@54.161.156.75:26656,2b35a42c54ec562fc1a54e29d8cb7f8818567f69@67.209.54.93:26661,04756c753a8aee0f7c316ed1b94107878c8a8df3@51.79.228.51:26656,ad9f08613da5dfff730b16caad33a11e1833faa0@57.128.144.225:26656,588cedb70fa1d98c14a2f2c1456bfa41e1a156a8@65.108.77.152:29539,ff1778dd3efe597033671780db55ed0508971921@5.9.138.213:26656,6e91c9f077eafc1014e06be6c7e4394bf4b1c960@38.242.255.29:26656,798484523508fccf2bf28f450781d5b902da066a@100.24.119.215:26656,cb6ae22e1e89d029c55f2cb400b0caa19cbe5523@3.98.186.232:26603,4e1c2471efb89239fb04a4b75f9f87177fd91d00@95.217.82.76:26656,35b583632f09260c21a3382844c6baa2d18bdc36@52.3.235.250:26656,ae0beffb17e1fd61367be434a4c72a0688757403@65.108.238.6:26656,2d588e1bc71431f6c677a9ed7f5ff8f7caa82573@65.109.64.50:26656,83c94142b93ee88ea143edb608789bd6c635c84c@185.207.250.46:26656,41a695fdd1c0bc6923d136d1eb5a71673dc168b3@173.234.17.196:27656,12d147256a5a876308f053cf301410f6e213c1ce@54.161.233.12:26656,bba10290da32f3cb41e15c3a192413666ce05cee@5.9.208.12:26656,c369eba335793639acb914cdd142deba857e6077@138.201.37.244:26656,8abde91c2bdbd12fcc94dbe4933c91a3fe9c55e4@65.108.237.179:26656,bdcb0bf2d57bf8b8f856fd34647ba9c4dc8bb6d7@141.98.219.175:26656,105a87f6bb8aca8e8475ad8fb5e044acc4096cd4@95.216.16.205:13456,5817ae31491d1d09399653a4a786ae5c5af5eaee@65.108.194.108:26656,6cb6a6b567b6e39360a5f27c01a297149e18c22a@65.108.227.181:26656,f3ec4d7d17325509cb44addc47bd8b59b00c674a@23.88.73.81:25656,7ff6e8c8263a094fb37bdb88cfa16c58ce147075@138.201.62.50:28095,bf2cd8605d0020a212497cfa2fbc0d8e5edff91e@18.234.128.4:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.evmosd/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.evmosd/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.evmosd/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.evmosd/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.evmosd/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/evmosd.service > /dev/null << EOF
[Unit]
Description=Evmos Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which evmosd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

evmosd tendermint unsafe-reset-all --home $HOME/.evmosd --keep-addr-book

SNAP_RPC="https://evmos.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.evmosd/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable evmosd
sudo systemctl restart evmosd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
