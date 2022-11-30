sudo systemctl stop sifnoded

cd || return
rm -rf sifnode
git clone https://github.com/Sifchain/sifnode.git
cd sifnode || return
git checkout v1.1.0-beta
make install

sudo systemctl restart sifnoded