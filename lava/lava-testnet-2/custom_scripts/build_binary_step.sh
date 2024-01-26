# Clone project repository
cd && rm -rf lava
git clone https://github.com/lavanet/lava
cd lava
git checkout ${tag}

# Build binary
export LAVA_BINARY=lavad
make install
