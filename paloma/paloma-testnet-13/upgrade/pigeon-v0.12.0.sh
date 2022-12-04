sudo systemctl stop pigeond

# upgrade pigeon
curl -L https://github.com/palomachain/pigeon/releases/download/v0.12.0/pigeon_Linux_x86_64.tar.gz > pigeon.tar.gz
tar -xvzf pigeon.tar.gz
rm -rf pigeon.tar.gz
sudo mv -f pigeon /usr/local/bin/pigeon
pigeon version # v0.12.0

sudo systemctl start pigeond
