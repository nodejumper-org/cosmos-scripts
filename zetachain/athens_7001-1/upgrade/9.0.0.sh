sudo systemctl stop zetacored

mkdir -p $HOME/go/bin
curl -L https://github.com/zeta-chain/node/releases/download/v9.0.0/zetacored-ubuntu-20-amd64 > $HOME/go/bin/zetacored
chmod +x $HOME/go/bin/zetacored

sudo systemctl start zetacored
