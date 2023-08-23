sudo systemctl stop noisd

cd || return
rm -rf noisd
git clone https://github.com/noislabs/noisd.git
cd noisd
git checkout v1.0.4
make install
noisd version # 1.0.4

rm -rf $HOME/.noisd/wasm/wasm/cache/

sudo systemctl start noisd
