sudo systemctl stop defundd

defundd tendermint unsafe-reset-all --home $HOME/.defund
defundd config chain-id defund-private-3

cd || return
curl -L https://github.com/defund-labs/testnet/raw/main/defund-private-3/defund-private-3-gensis.tar.gz > defund-private-3-gensis.tar.gz
tar -xvzf defund-private-3-gensis.tar.gz
rm -rf defund-private-3-gensis.tar.gz
sudo mv -f genesis.json $HOME/.defund/config/genesis.json
sha256sum $HOME/.defund/config/genesis.json # 1a10121467576ab6f633a14f82d98f0c39ab7949102a77ab6478b2b2110109e3

seeds=""
peers="6366ac3af3995ecbc48c13ce9564aef0c7a6d7df@defund-testnet.nodejumper.io:28656,03d46eae18d935a2e820735563ab01abb17d4cb6@65.108.235.107:29656,081a38c22f5c1915c3c38b529ef112370b45e290@161.97.91.80:26656,0cccc6e27f4aaf1f339905f8ad6a589467aeecc7@43.155.61.87:26656,80999d2aa81628c07454cc8ad4925fc6b44bdde0@206.217.140.82:26656,8715ed67b8833997d8cbfba985dbfc389a5a45dc@43.154.103.36:26656,5a1d2ab416788f41da94e3d993aeefba4618c288@192.210.206.198:26656,41a997be04de03c085f02073cdda4192f48c8330@216.127.190.109:26656,dfba70b73435b2540ebfa953cb1ca32193a957e6@43.159.194.246:26656,65e5fd83df6e42e686503f44dc0c685f722fa02a@43.154.53.71:26656,263616dba779061a18ded71dddb92928ea27a4ba@43.154.83.15:26656,e108c39c307864acbeceda3f4b2c77c99ec1bddd@185.16.38.136:36656,e4677ff91a0bfec8949de0c2d531b4bbffcb0ceb@92.119.112.231:36656,85b021ed71173a0825736891b06592a8eee7b4ca@43.156.112.45:26656,bdcaabb2384b1a59d12fbd57dd1d74a58edaf1b2@175.24.183.235:26656,45b50b7ad8df4d2661fc6f510bd9d490b5ec253d@43.134.202.178:26656,43452645f84db6827452f32869ddf3ce585937c5@43.156.111.103:26656,257de7d6825037b6c6de16aac4ebb9efd641b8a6@43.156.111.241:26656,58aef46a0286a6d50a7f687bfc35d62f85feec10@107.174.63.166:26656,c8fb3ab19dfac9f75085cb5e4fff36845773d8a6@43.154.60.157:26656,77b3dcacd513f7f7fa1b0247d716f464ad61e94d@65.109.65.210:34656,966e31c78c08aae8c74aa12702126141fb9cef7a@185.165.240.179:24666,92b164431c37b1b8e8cb66cbabcd688108c7479c@43.130.228.99:26656,38d23d7332b035eae29ba0abda13d32906c78c09@65.108.159.90:26656,ce62e6e53805ceae1f8f1087c5f7f6da13049cec@43.130.242.40:26656,53e2240528947ff8f7b037d347b7258f05ce88f0@89.179.68.98:27656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.defund/config/config.toml
sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1false|" $HOME/.defund/config/config.toml

sudo systemctl start defundd
