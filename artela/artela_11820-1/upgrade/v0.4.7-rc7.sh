# build new binary
cd && rm -rf artela
git clone https://github.com/artela-network/artela
cd artela
git checkout v0.4.7-rc7
make install

# download aspect lib
mkdir -p $HOME/.artelad/libs && cd $HOME/.artelad/libs
curl -L https://github.com/artela-network/artela/releases/download/v0.4.7-rc7/artelad_0.4.7_rc7_Linux_amd64.tar.gz -o artelad_0.4.7_rc7_Linux_amd64.tar.gz
tar -xvzf artelad_0.4.7_rc7_Linux_amd64.tar.gz
rm artelad_0.4.7_rc7_Linux_amd64.tar.gz

# update systemd service to use lib path
sudo systemctl stop artelad

sudo tee /etc/systemd/system/artelad.service > /dev/null << EOF
[Unit]
Description=Artela node service
After=network-online.target
[Service]
User=$USER
Environment="LD_LIBRARY_PATH=$HOME/.artelad/libs:\$LD_LIBRARY_PATH"
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
