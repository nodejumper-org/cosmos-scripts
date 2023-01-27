sudo systemctl stop strided

cd || return
rm -rf stride
git clone https://github.com/Stride-Labs/stride.git
cd stride || return
git checkout v5.0.0
make install

sudo systemctl start strided
