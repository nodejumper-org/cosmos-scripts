sudo systemctl stop pigeond
sudo systemctl stop palomad

# upgrade paloma
cd || return
rm -rf paloma
git clone https://github.com/palomachain/paloma.git
cd paloma || return
git checkout v1.10.1
make install
sudo mv -f $HOME/go/bin/palomad /usr/local/bin/palomad

sudo systemctl start pigeond
sudo systemctl start palomad
