sudo systemctl stop seid

cd || return
rm -rf sei-chain
git clone https://github.com/sei-protocol/sei-chain.git
cd sei-chain || return
git checkout 3.0.1
make install
seid version # 3.0.1

sudo systemctl start seid
