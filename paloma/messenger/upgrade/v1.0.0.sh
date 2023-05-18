sudo systemctl stop pigeond
sudo systemctl stop palomad

curl -L https://github.com/palomachain/paloma/releases/download/v1.0.0/paloma_Linux_x86_64.tar.gz > paloma.tar.gz
tar -xvzf paloma.tar.gz
rm -rf paloma.tar.gz
sudo mv -f palomad /usr/local/bin/palomad
palomad version # v1.0.0

curl -L https://github.com/palomachain/pigeon/releases/download/v1.0.0/pigeon_Linux_x86_64.tar.gz > pigeon.tar.gz
tar -xvzf pigeon.tar.gz
rm -rf pigeon.tar.gz
sudo mv -f pigeon /usr/local/bin/pigeon
pigeon version # v1.0.0

sudo systemctl start pigeond
sudo systemctl start palomad
