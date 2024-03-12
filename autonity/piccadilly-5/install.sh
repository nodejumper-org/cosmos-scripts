#!/bin/bash

# guide for ubuntu 22.04

# install packages
sudo apt update
sudo apt install -y gcc python3-pip python3.10-venv
python3 -m pip install --user pipx
sudo mv $HOME/.local/bin/* /usr/local/bin

# install go
source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/go_install.sh) -v 1.21.3

# install ethkey
cd $HOME && rm -rf go-ethereum
git clone https://github.com/ethereum/go-ethereum
cd go-ethereum
go install -v ./cmd/ethkey

# build autonity node binary
cd $HOME && rm -rf autonity
git clone https://github.com/autonity/autonity.git
cd autonity
git checkout v0.13.0
make autonity
sudo cp build/bin/autonity /usr/local/bin

# install aut CLI binary
pipx install --force git+https://github.com/autonity/aut
sudo mv $HOME/.local/bin/aut /usr/local/bin/aut
aut --version
# aut, version 0.4.0

# create dirs
mkdir -p $HOME/autonity-chaindata/autonity

# create keys (or import)
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
Description=Antonity Execution Layer
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME
Type=simple
ExecStart=$(which autonity) --datadir $HOME/autonity-chaindata --piccadilly --http --http.addr 0.0.0.0 --http.api aut,eth,net,txpool,web3,admin --http.vhosts * --ws --ws.addr 0.0.0.0 --ws.api aut,eth,net,txpool,web3,admin --bootnodes enode://48a10db920251436ee1d7989db6cbab734157d5bd3ec9d534021e4903fdab51407ba4fd936bd6af1d188e3f464374c437accefa40f0312eac9bc9ae6fc0a2782@34.105.239.129:30303,enode://9379179c8c0f7fec28dd3cca64da5d85f843e3b05ba24f6ae4f8d1bb688b4581f92c10e84e166328499987cf2da18668446dd7353724cf691ad2a931a0cbd88d@34.93.237.13:30303,enode://c7e8619c09c85c47a2bbda720ecec449ab1207574cc60d8ec451b109b407d7542cabc2683eedcf326009532e3aea2b748256bac1d50bf877c73eea4d633e8913@54.241.251.216:30303,enode://e7cea14b38d590066217b6639ee24f964b5ec3f5db127e460b695562495f5d04d2063b71a86baeaddbf318d204e4322dee2271c9dbcf462650f2547233fd2f67@178.205.102.224:30303,enode://219f542340d5f59e962f4a841b91825d098c61fee2751ec82c1440a4710b5c625d6c8fdc1bc3fc482369be83b23e59b3e983c8f463d39cb85f8d46665fca0bb4@217.66.20.45:30303,enode://d949e4858e2d3e06bd9f4b15de17b5bbdab111f9964b73cde40d78bc8af30cdf829072ad298cc744253aba74133b21eba214bc3b4cb42ead3f04c32c8b902656@92.255.196.146:30303
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
cd $HOME && rm -rf autonity-oracle
git clone https://github.com/autonity/autonity-oracle.git
cd autonity-oracle
git checkout v0.1.6
make autoracle
sudo mv build/bin/autoracle /usr/local/bin/autoracle
autoracle version
# autoracle, version 0.1.6

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
ExecStart=$(which autoracle) -key.file="$HOME/.autonity/keystore/oracle.key" -plugin.dir="$HOME/autonity-oracle/build/bin/plugins/" -plugin.conf="$HOME/autonity-oracledata/plugins-conf.yml" -key.password="" -ws="ws://127.0.0.1:9546"
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

# nodekey file, oracle private key hex, treasure address
autonity genOwnershipProof \
 --nodekey $HOME/autonity-chaindata/autonity/nodekey \
 --oraclekeyhex feeaaa12c4c005432f830174e9cfc77dc31ae4021a208d260583c68d5b9ccbe5 \
 0xC0BE9AD3146Da5595705600F15aA89830fd79Ee8
# Signature:
# 0xd783aa5ed1c15b2c3ca86e6ae34f0fd53b24705a4e69397bd290cc2150447d611567cefd84a0245b0a55ebc9d593b9dbd890f451a7b8975010a0ab1bb13856b5018daa13f0aa3fbbc97764805706100acffb69fabfd3af01cf968bddc06efe8c042a38114fbd030803928b3c6782cebb1b50300a186ceba8edca3bfd6053d2f33300

# compute validator address
aut validator compute-address enode://a91e9bec3fa443ec78122074838e27103ccf9c0a3f1ab08235df3d2ff6868661dfcb3914e51625de9f36b74094b117c6609ec89fe19507e057cc4e4fbf53765d@65.109.120.190:30303
# computed validator address:
# 0xd6B351f977a28aaAace7C873Ff8f91C3550fdf0B

# treasure key file, enode, oracle address, ownerproof signature
aut validator register \
 --keyfile $HOME/.autonity/keystore/treasure.key \
 enode://a91e9bec3fa443ec78122074838e27103ccf9c0a3f1ab08235df3d2ff6868661dfcb3914e51625de9f36b74094b117c6609ec89fe19507e057cc4e4fbf53765d@65.109.120.190:30303 \
 0x03b0132591b5D0498449097787993B1C0e917A53 \
 0xd783aa5ed1c15b2c3ca86e6ae34f0fd53b24705a4e69397bd290cc2150447d611567cefd84a0245b0a55ebc9d593b9dbd890f451a7b8975010a0ab1bb13856b5018daa13f0aa3fbbc97764805706100acffb69fabfd3af01cf968bddc06efe8c042a38114fbd030803928b3c6782cebb1b50300a186ceba8edca3bfd6053d2f33300 | aut tx sign -k $HOME/.autonity/keystore/treasure.key - | aut tx send -

# bond your validator tx
# treasure key file, computed validator address, amount (0.7 ATN)
aut validator bond \
 --keyfile $HOME/.autonity/keystore/treasure.key \
 --validator 0xd6B351f977a28aaAace7C873Ff8f91C3550fdf0B 0.7 | aut tx sign -k $HOME/.autonity/keystore/treasure.key - | aut tx send -

# import nodekey as keyfile, and rename UTC--2023... to nodekey and move it to keystore
aut account import-private-key $HOME/autonity-chaindata/autonity/nodekey
mv $HOME/.autonity/keystore/UTC--* $HOME/.autonity/keystore/nodekey

# use validator computed address from one of previous step
sudo tee <<EOF >/dev/null $HOME/.autrc
[aut]
rpc_endpoint=ws://127.0.0.1:8546
keyfile=$HOME/.autonity/keystore/nodekey
validator=0xd6B351f977a28aaAace7C873Ff8f91C3550fdf0B
EOF

# sign message with nodekey
aut account sign-message "validator onboarded"

# now you can register a validator here: https://game.autonity.org/awards/register-validator.html

# sign message with nodekey for Open door task: https://game.autonity.org/round-4/node-tasks/open-door/
aut account sign-message "public rpc"