cd && rm -rf initia
git clone https://github.com/initia-labs/initia
cd initia
git checkout v0.2.15

make install

sudo systemctl restart initiad
