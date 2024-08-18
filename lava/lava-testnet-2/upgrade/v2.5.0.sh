cd && rm -rf lava
git clone https://github.com/lavanet/lava
cd lava
git checkout v2.5.0
make install-all

sudo systemctl restart lavad
