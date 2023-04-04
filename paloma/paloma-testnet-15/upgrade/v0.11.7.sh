sudo systemctl stop palomad

cd || return
rm -rf paloma
git clone https://github.com/palomachain/paloma.git
cd paloma || return
git checkout v0.11.7
make install
sudo mv -f $HOME/go/bin/palomad /usr/local/bin/palomad
palomad version # v0.11.7

sudo systemctl start palomad
