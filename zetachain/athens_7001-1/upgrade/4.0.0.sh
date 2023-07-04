sudo systemctl stop zetacored

mkdir -p $HOME/go/bin
curl -L https://zetachain-external-files.s3.amazonaws.com/binaries/athens3/v4.0.0/zetacored-ubuntu-20-amd64 > $HOME/go/bin/zetacored
chmod +x $HOME/go/bin/zetacored

sudo systemctl start zetacored
