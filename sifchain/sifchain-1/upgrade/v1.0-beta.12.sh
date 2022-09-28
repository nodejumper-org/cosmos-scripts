sudo systemctl stop sifnoded

cd || return
cd sifnode || return
git fetch --all
git checkout v1.0-beta.12
make install

sudo systemctl restart sifnoded
