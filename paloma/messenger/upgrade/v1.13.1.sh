# upgrade paloma
cd && rm -rf paloma
git clone -b v1.13.1 https://github.com/palomachain/paloma.git
cd paloma
make install
sudo mv -f $HOME/go/bin/palomad "$(which palomad)"

sudo systemctl restart palomad
