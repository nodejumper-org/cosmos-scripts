sudo systemctl stop lavad

export LAVA_BINARY=lavad

cd || return
rm -rf lava
git clone https://github.com/lavanet/lava
cd lava || return
git checkout v0.22.0
make install
lavad version

sudo systemctl start lavad
