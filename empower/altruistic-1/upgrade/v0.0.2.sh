sudo systemctl stop empowerd

cd || return
rm -rf empowerchain
git clone https://github.com/empowerchain/empowerchain.git
cd empowerchain || return
git checkout v0.0.2
cd chain || return
make install

sudo systemctl restart empowerd
