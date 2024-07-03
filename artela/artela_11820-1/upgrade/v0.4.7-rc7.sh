# build new binary
cd && rm -rf artela
git clone https://github.com/artela-network/artela
cd artela
git checkout v0.4.7-rc7
make install

# download aspect lib
mkdir -p $HOME/.artela/libs && cd $HOME/.artela/libs
curl -L https://github.com/artela-network/artela/releases/download/v0.4.7-rc7/artelad_0.4.7_rc7_Linux_amd64.tar.gz -o artelad_0.4.7_rc7_Linux_amd64.tar.gz
tar -xvzf artelad_0.4.7_rc7_Linux_amd64.tar.gz
rm artelad_0.4.7_rc7_Linux_amd64.tar.gz

# update seeds and peers
SEEDS="211536ab1414b5b9a2a759694902ea619b29c8b1@47.251.14.47:21256,d89e10d917f6f7472125aa4c060c05afa78a9d65@47.251.32.165:26656,bec6934fcddbac139bdecce19f81510cb5e02949@47.254.24.106:26656,32d0e4aec8d8a8e33273337e1821f2fe2309539a@47.88.58.36:26656,1bf5b73f1771ea84f9974b9f0015186f1daa4266@47.251.14.47:26656"
PEERS="dfda88777cbf1eba20089e9fad82f917e263fefe@135.125.67.241:26656,170d603eae3e885f62c2fbf4ec34c082e8f55e2a@3.142.119.230:26656,1d929a861c47fd09dee4e9c0dbcbdf6e776a0846@195.201.61.35:26656,ae77c67f1fde4539b62645c92af808902a4aadc3@89.163.254.25:26656,0c4386d0402d8dfb0a472736ee3b6de3e77d6dab@188.40.197.38:26656,f22a06b4ac34a353a00a21d7005bd06c6c3ecfe8@185.110.188.152:30656,8069d19fef73f6fc75cf04630115bdbbb70babb5@65.109.126.231:27856,7d5ce5fa49f8e9e11a80de1ab22bd98169d8e168@88.198.131.77:30656,00bf37502e023ea690a0cb8b7c2195747defb848@161.97.162.96:23456,5532aba5673a3e6066233089718cec3c70a14db4@89.163.150.244:26656,c2b525fd1ff2b1c1e82e8e54deb081da3dd3d514@88.198.131.74:30656,4dae0ae76be348c377accf375249af0aeb3124f8@78.31.64.138:26656,44d8b040b3be3f9c6491ba8ad1dafb726a01f1a1@23.88.68.47:19656,a4557adf0a37bba91d627d94a74ce7e3f70dccda@168.119.179.16:26656,9bf0f78376f849e4c463232831d9f90864dc5e9c@109.199.105.150:25656,5c5bf1802c18151dc72573746ce81489850e69a5@195.201.193.242:26656,0627dcacdfa35115d335d4116e08811f2dd4cba5@188.40.197.39:26656,a3076a058ba5ac756588787658e76d61e87bd363@207.244.242.60:3456,66df5b61c9675143318eedd6b561388bb287a088@94.72.99.153:26656,3eaeb7326e6209e309b04cf4411b21abb035b6e6@88.198.131.78:26656,fa22284df56a034a83e263f6ceb5c00055736720@95.217.91.198:26656,1b8732842fd8273705605e4958566edefefa1340@158.220.109.104:26656,b91214271f15d729e1c9e2463f84cdb16950b4b5@188.40.250.205:26656,87d7660909447800d61ec37863da377ac66de53e@116.203.49.2:26656,a25931dcd4b1dfbcd71b2377b610ebb3e46af82e@5.9.196.230:26656,057d731dc9041b6c971646bd3282206ee18ca941@88.198.131.75:30656,cc27839e6f251607013c11422ea400d785ac56e1@5.9.196.224:26656,b0475aaf0bee05abd007d1ff5a833bb46ec0daf4@162.55.22.230:26656,5bc79f27e6390fb71380ce8274fa6d7d566ef54c@136.243.171.152:26656,07d6f980537a3ee178ab4a9fb5de3980017cf8c4@136.243.153.174:26656,8ef8348d9d0050851a73508f2a9abaf1fafdbd81@65.109.32.148:26176"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.rizon/config/config.toml

# update systemd service to use lib path
sudo systemctl stop artelad

sudo tee /etc/systemd/system/artelad.service > /dev/null << EOF
[Unit]
Description=Artela node service
After=network-online.target
[Service]
User=$USER
Environment="LD_LIBRARY_PATH=$HOME/.artela/libs:\$LD_LIBRARY_PATH"
ExecStart=$(which artelad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload

# start the service
sudo systemctl start artelad
