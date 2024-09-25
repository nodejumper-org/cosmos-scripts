sudo systemctl stop wardend

cd $HOME && rm -rf wardenprotocol
git clone https://github.com/warden-protocol/wardenprotocol
cd  wardenprotocol
git checkout v0.2.0
make install-wardend

sudo systemctl start wardend