sudo systemctl stop archwayd

cd $HOME || return
rm -rf archway
git clone https://github.com/archway-network/archway.git
cd archway || return
git checkout v1.0.0-rc.4
make install
archwayd version

sudo systemctl start archwayd
