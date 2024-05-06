cd && rm -rf lava
git clone https://github.com/lavanet/lava
cd lava
git checkout v2.0.0
make install-all

sudo systemctl restart lavad
