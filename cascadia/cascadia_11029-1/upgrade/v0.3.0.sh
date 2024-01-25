sudo systemctl stop cascadiad

cd && rm -rf cascadia
git clone https://github.com/CascadiaFoundation/cascadia
cd cascadia
git checkout v0.3.0
make install

sudo systemctl start cascadiad
