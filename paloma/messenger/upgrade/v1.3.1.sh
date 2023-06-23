sudo systemctl stop pigeond
sudo systemctl stop palomad

# upgrade paloma
curl -L https://github.com/palomachain/paloma/releases/download/v1.3.1/paloma_Linux_x86_64.tar.gz > paloma.tar.gz
tar -xvzf paloma.tar.gz
rm paloma.tar.gz
sudo mv -f paloma /usr/local/bin/paloma
palomad version # v1.3.1

# upgrade pigeon
curl -L https://github.com/palomachain/pigeon/releases/download/v1.2.1/pigeon_Linux_x86_64.tar.gz > pigeon.tar.gz
tar -xvzf pigeon.tar.gz
rm pigeon.tar.gz
sudo mv -f pigeon /usr/local/bin/pigeon
pigeon version # v1.2.1

sudo systemctl start pigeond
sudo systemctl start palomad
