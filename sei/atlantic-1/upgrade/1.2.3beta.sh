sudo systemctl stop seid

cd || return
rm -rf sei-chain
git clone https://github.com/sei-protocol/sei-chain.git
cd sei-chain || return
git checkout 1.2.3beta
make install

sudo systemctl restart seid
