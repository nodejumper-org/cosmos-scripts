sudo systemctl stop empowerd

cd || return
rm -rf empowerchain
git clone https://github.com/EmpowerPlastic/empowerchain
cd empowerchain/chain || return
git checkout v2.0.0
make install

sudo systemctl start empowerd