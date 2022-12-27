sudo systemctl stop rebusd

cd $HOME/rebus.core || return
git fetch
git checkout v0.0.4
make install
rebusd version #HEAD.2bd70031d6c380d7d2cf4de8cdf546b060f54260

sudo systemctl start rebusd
