sudo systemctl stop firmachaind

cd || return
rm -rf firmachain
git clone https://github.com/firmachain/firmachain
cd firmachain || return
git checkout 0.3.5-patch
make install
firmachaind version # 0.3.5-patch

sudo systemctl start firmachaind
