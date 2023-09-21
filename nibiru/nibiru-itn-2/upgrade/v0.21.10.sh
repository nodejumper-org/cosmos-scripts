sudo systemctl stop nibid

cd || return
rm -rf nibiru
git clone https://github.com/NibiruChain/nibiru
cd nibiru || return
git checkout v0.21.10
make install

sudo systemctl start nibid
