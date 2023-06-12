sudo systemctl stop uptickd

cd || return
rm -rf uptick
git clone https://github.com/UptickNetwork/uptick.git
cd uptick || return
git checkout v0.2.8
make install

sudo systemctl start uptickd
