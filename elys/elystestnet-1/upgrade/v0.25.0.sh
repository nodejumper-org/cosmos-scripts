sudo systemctl stop elysd

cd || return
rm -rf elys
git clone https://github.com/elys-network/elys
cd elys
git checkout v0.25.0
make install

sudo systemctl start elysd
