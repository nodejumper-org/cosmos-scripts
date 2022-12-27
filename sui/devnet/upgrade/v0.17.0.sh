sudo systemctl stop suid

version=$(wget -qO- https://api.github.com/repos/nodejumper-org/sui/releases/latest | jq -r ".tag_name")
curl -L https://github.com/nodejumper-org/sui/releases/download/${version}/sui-linux-amd64-${version}.tar.gz > sui-linux-amd64-latest.tar.gz
sudo tar -xvzf sui-linux-amd64-latest.tar.gz -C /usr/local/bin/
rm -rf sui-linux-amd64-latest.tar.gz
sui-node -V # sui-node 0.17.0
sui -V # sui 0.17.0

sudo systemctl start suid