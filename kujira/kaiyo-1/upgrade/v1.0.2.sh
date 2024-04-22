cd && rm -rf core
git clone https://github.com/Team-Kujira/core.git
cd core || return
git checkout v1.0.2
make install

sudo systemctl restart kujirad
