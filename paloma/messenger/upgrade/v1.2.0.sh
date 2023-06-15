sudo systemctl stop palomad

# upgrade paloma
cd || return
rm -rf paloma
git clone https://github.com/palomachain/paloma.git
cd paloma || return
git checkout v1.2.0
make install
sudo mv -f $HOME/go/bin/palomad /usr/local/bin/palomad
palomad version # v1.2.0

sudo systemctl start palomad
