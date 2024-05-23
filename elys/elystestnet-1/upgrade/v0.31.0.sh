cd && rm -rf elys
git clone https://github.com/elys-network/elys
cd elys
git checkout fix/v0.31.0-increase-max-block-size-disable-allocateTokens
git tag -f v0.31.0
make install

sudo systemctl restart elysd
