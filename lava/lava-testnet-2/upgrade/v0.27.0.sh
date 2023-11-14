sudo systemctl stop lavad

export LAVA_BINARY=lavad

cd || return
rm -rf lava
git clone https://github.com/lavanet/lava
cd lava || return
git checkout v0.27.0
make install

sudo systemctl start lavad
