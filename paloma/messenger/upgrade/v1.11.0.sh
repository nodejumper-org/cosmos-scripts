sudo systemctl stop palomad

# upgrade paloma
cd || return
rm -rf paloma
git clone https://github.com/palomachain/paloma.git
cd paloma || return
git checkout v1.11.0
make install
sudo mv -f $HOME/go/bin/palomad "$(which palomad)"

sudo systemctl start palomad
