cd && rm -rf andromedad
git clone https://github.com/andromedaprotocol/andromedad
cd andromedad
git checkout andromeda-1-v0.1.1

make install

sudo systemctl restart andromedad
