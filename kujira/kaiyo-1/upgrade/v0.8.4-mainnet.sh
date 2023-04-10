sudo systemctl stop kujirad

cd || return
rm -rf core
git clone https://github.com/Team-Kujira/core.git
cd core || return
git checkout v0.8.4-mainnet
make install
kujirad version # v0.8.4-mainnet

sudo systemctl start kujirad
