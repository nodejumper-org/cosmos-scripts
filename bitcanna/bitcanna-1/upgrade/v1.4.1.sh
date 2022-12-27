sudo systemctl stop bcnad

cd || return
cd bcna || return
git fetch --all
git checkout v1.4.1
make install

sudo systemctl start bcnad
