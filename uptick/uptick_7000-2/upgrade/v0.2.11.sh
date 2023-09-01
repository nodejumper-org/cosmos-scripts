sudo systemctl stop uptickd

cd $HOME || return
rm -rf uptick
git clone https://github.com/UptickNetwork/uptick.git
cd uptick || return
git checkout v0.2.11
make build -B
sudo mv build/uptickd /usr/local/bin/uptickd
uptickd version # v0.2.11

sudo systemctl start uptickd
