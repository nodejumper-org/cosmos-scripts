sudo systemctl stop canined

cd && rm -rf canine-chain
git clone https://github.com/JackalLabs/canine-chain.git
cd canine-chain || return
git checkout v3.2.0-rc.1
make install

sudo systemctl start canined
