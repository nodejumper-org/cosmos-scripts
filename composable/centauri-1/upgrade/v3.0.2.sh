sudo systemctl stop banksyd

cd || return
rm -rf composable-testnet
git clone https://github.com/notional-labs/composable-testnet.git
cd composable-testnet || return
git checkout v3.0.2
make install

sudo systemctl start banksyd
