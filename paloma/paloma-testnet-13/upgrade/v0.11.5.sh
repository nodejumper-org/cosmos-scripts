sudo systemctl stop pigeond
sudo systemctl stop palomad

wget -O - https://github.com/palomachain/paloma/releases/download/v0.11.5/paloma_Linux_x86_64.tar.gz |
sudo tar -C /usr/local/bin -xvzf - palomad

wget -O - https://github.com/palomachain/pigeon/releases/download/v0.11.5/pigeon_Linux_x86_64.tar.gz |
sudo tar -C /usr/local/bin -xvzf - pigeon

palomad version # v0.11.5
pigeon version # v0.11.5

sudo systemctl start pigeond
sudo systemctl start palomad

sudo journalctl -u pigeond -f --no-hostname -o cat
