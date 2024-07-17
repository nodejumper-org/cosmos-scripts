cd && rm -rf canine-chain
git clone https://github.com/JackalLabs/canine-chain.git
cd canine-chain
git checkout v4.0.0-beta.5
make install

sudo systemctl restart canined
