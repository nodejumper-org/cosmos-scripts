cd && rm -rf andromedad
git clone https://github.com/andromedaprotocol/andromedad
cd andromedad
git checkout v0.1.1-patch

make install

sudo systemctl restart andromedad
