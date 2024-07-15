cd && rm -rf elys
git clone https://github.com/elys-network/elys
cd elys
git checkout v0.38.0
make install

sudo systemctl restart elysd
