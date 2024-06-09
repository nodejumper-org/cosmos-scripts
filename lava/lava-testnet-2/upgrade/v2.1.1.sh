cd && rm -rf lava
git clone https://github.com/lavanet/lava
cd lava
git checkout v2.1.1
make install-all

sudo systemctl restart lavad
