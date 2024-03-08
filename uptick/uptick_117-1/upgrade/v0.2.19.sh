sudo systemctl stop uptickd

cd $HOME && rm -rf uptick
git clone https://github.com/UptickNetwork/uptick.git
cd uptick || return
git checkout v0.2.19
make build -B
sudo mv build/uptickd $(which uptickd)

sudo systemctl start uptickd
