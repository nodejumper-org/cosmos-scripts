cd && rm -rf core
git clone https://github.com/Team-Kujira/core.git
cd core
git checkout v1.1.0
make install

sudo systemctl restart kujirad
