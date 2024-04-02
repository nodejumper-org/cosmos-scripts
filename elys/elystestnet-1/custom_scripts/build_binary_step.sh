# Clone project repository
cd && rm -rf elys
git clone https://github.com/elys-network/elys
cd elys
git checkout ${tag}

# Build binary
ROCKSDB=1 LD_LIBRARY_PATH=/usr/local/lib make install