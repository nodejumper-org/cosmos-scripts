sudo systemctl stop canined

cd || return
rm -rf canine-chain
git clone https://github.com/JackalLabs/canine-chain.git
cd canine-chain || return
git checkout v2.1.0
make install

sudo systemctl start canined
