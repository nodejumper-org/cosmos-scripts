sudo systemctl stop lavad

cd || return
rm -rf lava
git clone https://github.com/lavanet/lava
cd lava || return
git checkout v0.11.2
make install
lavad version

sudo systemctl start lavad
