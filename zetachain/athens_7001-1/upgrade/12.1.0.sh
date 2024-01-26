sudo systemctl stop zetacored

curl -L https://github.com/zeta-chain/node/releases/download/v12.1.0/zetacored-linux-amd64 > $HOME/go/bin/zetacored
chmod +x $HOME/go/bin/zetacored

sudo systemctl start zetacored
