sudo systemctl stop palomad

cd || return
rm -rf paloma
git clone https://github.com/palomachain/paloma.git
cd paloma || return
git checkout v1.0.0-beta2
make install
sudo mv -f $HOME/go/bin/palomad /usr/local/bin/palomad
palomad version # v1.0.0-beta2

sudo systemctl start palomad
