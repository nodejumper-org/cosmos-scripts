sudo systemctl stop nibid

cd || return
rm -rf nibiru
git clone https://github.com/NibiruChain/nibiru
cd nibiru || return
git checkout v0.16.3
make install
nibid version # v0.16.3

sudo systemctl start nibid
