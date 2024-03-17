sudo systemctl stop palomad

# upgrade paloma
cd || return
rm -rf paloma
git clone https://github.com/palomachain/paloma.git
cd paloma || return
git checkout v1.12.2
make install
sudo mv -f $HOME/go/bin/palomad "$(which palomad)"

# upgrade pigeon
curl -L https://github.com/palomachain/pigeon/releases/download/v1.10.3/pigeon_Linux_x86_64.tar.gz > pigeon.tar.gz
tar -xvzf pigeon.tar.gz
rm pigeon.tar.gz
sudo mv -f pigeon "$(which pigeon)"

sudo systemctl start palomad
