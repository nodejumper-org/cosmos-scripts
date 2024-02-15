sudo systemctl stop elysd

cd && rm -rf elys
git clone https://github.com/elys-network/elys
cd elys
git checkout v0.29.12
make install

sudo systemctl start elysd
