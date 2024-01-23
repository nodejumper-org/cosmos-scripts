sudo systemctl stop bcnad

cd || return
rm -rf bcna
git clone https://github.com/BitCannaGlobal/bcna.git
cd bcna || return
git checkout v3.0.0
make install

sudo systemctl start bcnad
