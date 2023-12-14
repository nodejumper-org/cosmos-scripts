#!/bin/bash

# install packages
sudo apt update
sudo apt install -y gcc python3-pip python3.10-venv
python3 -m pip install --user pipx
sudo mv $HOME/.local/bin/* /usr/local/bin

# install go
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.20.12.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' | tee -a $HOME/.bash_profile)
source $HOME/.bash_profile

# build autonity node binary
git clone https://github.com/autonity/autonity.git
cd autonity
git checkout tags/v0.12.2 -b v0.12.2
make autonity
sudo cp build/bin/autonity /usr/local/bin/autonity

# install aut CLI binary
pipx install --force 'https://github.com/autonity/aut/releases/download/v0.3.0.dev1/aut-0.3.0.dev1-py3-none-any.whl'
sudo mv $HOME/.local/bin/aut /usr/local/bin/aut

# create dirs
mkdir $HOME/autonity-chaindata

# create keys
mkdir -p $HOME/.autonity/keystore
aut account new -k $HOME/.autonity/keystore/treasure.key
aut account new -k $HOME/.autonity/keystore/oracle.key

# create client CLI config
sudo tee <<EOF >/dev/null $HOME/.autrc
[aut]
rpc_endpoint=ws://127.0.0.1:8546
keyfile=$HOME/.autonity/keystore/treasure.key
EOF

# create and start autonityd systemd service
sudo tee <<EOF >/dev/null /etc/systemd/system/autonityd.service
[Unit]
Description=Antony Execution Layer
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME
Type=simple
ExecStart=$(which autonity) --datadir $HOME/autonity-chaindata --piccadilly --http --http.addr 0.0.0.0 --http.api aut,eth,net,txpool,web3,admin --http.vhosts * --ws --ws.addr 0.0.0.0 --ws.api aut,eth,net,txpool,web3,admin --bootnodes enode://3c7f26eb85a7fc37d5ea64c07598a28dd58f507477a88b2144179a4a162c6cba9407389d39c76386126f0604dd53141680d8075b6d210a22cc38c3a8dd877711@35.246.7.21:30303,enode://08e2ed9ca80772ce32e3b56fba3469e33a034a66780e4852586e38db657658fdc610cfb7345543a01277eb53af458ef7cac0b66570ac1982011f24d3832d782c@34.100.165.124:30303,enode://d820e4d53f1e47443c23f2db28b251ca8b8dc207a1b0a0e36ae1bbeb63d0cea4f00dabb61e5daf27468f022adc8780dfd181c57ce0db16a9668dd72e18ecac6b@159.203.156.236:30303,enode://28ad78c1699b981322575c561e3cb2faf4e1239acf6ff85af132763f6dda59366b216798dc2f5f6455f48b3ddef365fb43280d82bffcdbbf5f14bd31309636d0@77.37.176.99,enode://6326a8d4a4d8fc4805c4391d25e3b17205aebc65004753a84417529f5554916f10fc06d7b368f4237cb27c35c82b1075781cb03668af244fa828bedfc4f0bf87@65.108.72.253:30303,enode://c5187fa38f0ab62bc12b03ef04de7d5928cfdf350318a357f21ca43487dd3a311d6ff63ba0f2b5f8dd6c8d336b954efe4d5275f935916ed1fd5ca347129fa0f7@78.107.234.44:30303
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable autonityd
sudo systemctl restart autonityd
sudo journalctl -u autonityd -f -o cat --no-hostname

#####################
### INSTALL ORACLE
#####################

# create dir for oracle data
mkdir $HOME/autonity-oracledata

# build oracle binary
git clone https://github.com/autonity/autonity-oracle.git
cd autonity-oracle
git checkout v0.1.4
make autoracle
sudo mv build/bin/autoracle /usr/local/bin/autoracle

# create oracle config (! use your own API keys !)
sudo tee <<EOF >/dev/null $HOME/autonity-oracledata/plugins-config.yml
# sample: https://github.com/autonity/autonity-oracle/blob/master/config/plugins-conf.yml

  - name: forex_currencyfreaks              # required, it is the plugin file name in the plugin directory.
    key: 4149677c4dcc4974ae23c28d897b9961   # required, visit https://currencyfreaks.com to get your key, and replace it.
    refresh: 3600

  - name: forex_openexchangerate            # required, it is the plugin file name in the plugin directory.
    key: 85a7dbbb00ee40ed8d824e86432a0216   # required, visit https://openexchangerates.org to get your key, and replace it.
    refresh: 3600

  - name: forex_currencylayer               # required, it is the plugin file name in the plugin directory.
    key: de18fb876d0aad0efd912fa420273dd3   # required, visit https://currencylayer.com  to get your key, and replace it.
    refresh: 3600

  - name: forex_exchangerate                # required, it is the plugin file name in the plugin directory.
    key: 65874b3b5ebea256dff26722           # required, visit https://www.exchangerate-api.com to get your key, and replace it.
    refresh: 3600

  - name: sim_plugin
    endpoint: simfeed.bakerloo.autonity.org
    scheme: https
EOF

# create and start antonity oracle systemd service
sudo tee <<EOF >/dev/null /etc/systemd/system/antoracled.service
[Unit]
Description=Autonity Oracle Server
After=syslog.target network.target
[Service]
User=$USER
WorkingDirectory=$HOME
Type=simple
ExecStart=$(which autoracle) -key.file="$HOME/.autonity/keystore/oracle.key" -plugin.dir="$HOME/autonity-oracle/build/bin/plugins/" -plugin.conf="$HOME/autonity-oracledata/plugins-config.yml" -key.password="" -ws="ws://127.0.0.1:8546"
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable antoracled
sudo systemctl restart antoracled
sudo journalctl -u antoracled -f -o cat --no-hostname

#######################################
### Register your validator in testnet
#######################################

# register https://game.autonity.org/getting-started/register.html
# AUTONITY ADDRESS - treasure address
# sign message:
aut account sign-message "I have read and agree to comply with the Piccadilly Circus Games Competition Terms and Conditions published on IPFS with CID QmVghJVoWkFPtMBUcCiqs7Utydgkfe19wkLunhS5t57yEu"

# after the command you will see the private key from the oracle account! It must be used in the item getownershipproof.
ethkey inspect --private $HOME/.autonity/keystore/oracle.key

# nodekey, oraclekey, treasure address
autonity genOwnershipProof \
 --nodekey $HOME/autonity-chaindata/autonity/nodekey \
 --oraclekey $HOME/.autonity/pk/oracle.pk \
 0xC0BE9AD3146Da5595705600F15aA89830fd79Ee8
# Signature:
# 0xd783aa5ed1c15b2c3ca86e6ae34f0fd53b24705a4e69397bd290cc2150447d611567cefd84a0245b0a55ebc9d593b9dbd890f451a7b8975010a0ab1bb13856b5018daa13f0aa3fbbc97764805706100acffb69fabfd3af01cf968bddc06efe8c042a38114fbd030803928b3c6782cebb1b50300a186ceba8edca3bfd6053d2f33300

# get enode - aut node info
aut validator compute-address enode://a91e9bec3fa443ec78122074838e27103ccf9c0a3f1ab08235df3d2ff6868661dfcb3914e51625de9f36b74094b117c6609ec89fe19507e057cc4e4fbf53765d@65.109.120.190:30303
# 0xd6B351f977a28aaAace7C873Ff8f91C3550fdf0B

# treasure key, enode, oracle address, ownerproof signature
aut validator register \
 --keyfile $HOME/.autonity/keystore/treasure.key \
 enode://a91e9bec3fa443ec78122074838e27103ccf9c0a3f1ab08235df3d2ff6868661dfcb3914e51625de9f36b74094b117c6609ec89fe19507e057cc4e4fbf53765d@65.109.120.190:30303 \
 0x03b0132591b5D0498449097787993B1C0e917A53 \
 0xd783aa5ed1c15b2c3ca86e6ae34f0fd53b24705a4e69397bd290cc2150447d611567cefd84a0245b0a55ebc9d593b9dbd890f451a7b8975010a0ab1bb13856b5018daa13f0aa3fbbc97764805706100acffb69fabfd3af01cf968bddc06efe8c042a38114fbd030803928b3c6782cebb1b50300a186ceba8edca3bfd6053d2f33300 | aut tx sign -k $HOME/.autonity/keystore/treasure.key - | aut tx send -

# bond your validator tx
aut validator bond \
 --keyfile $HOME/.autonity/keystore/treasure.key \
 --validator 0xd6B351f977a28aaAace7C873Ff8f91C3550fdf0B 0.7 | aut tx sign -k $HOME/.autonity/keystore/treasure.key - | aut tx send -

# import nodekey as keyfile
aut account import-private-key $HOME/autonity-chaindata/autonity/nodekey
# 0x3Cb27571B006C1342BA3c9e986955DF8E4A833CF  /root/.autonity/keystore/UTC--2023-12-08T20-30-19.520537000Z--3cb27571b006c1342ba3c9e986955df8e4a833cf
# переименовать фаил кошелька (UTC--2023...) на nodekey

# use validator computed address from one of previous step
sudo tee <<EOF >/dev/null $HOME/.autrc
[aut]
rpc_endpoint=ws://127.0.0.1:8546
keyfile=$HOME/.autonity/keystore/nodekey
validator=0xd6B351f977a28aaAace7C873Ff8f91C3550fdf0B
EOF

aut account sign-message "validator onboarded"

# register a validator here: https://game.autonity.org/awards/register-validator.html
