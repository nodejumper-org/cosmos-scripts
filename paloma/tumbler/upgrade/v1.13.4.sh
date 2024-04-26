# upgrade palomad to v1.13.4
cd && rm -rf paloma
git clone -b v1.13.4 https://github.com/palomachain/paloma.git
cd paloma
make build
sudo mv -f build/palomad "$(which palomad)"

# upgrade pigeon to v1.11.1
cd && rm -rf pigeon
git clone -b v1.11.1 https://github.com/palomachain/pigeon
cd pigeon
make build
sudo mv -f build/pigeon "$(which pigeon)"

sudo systemctl restart pigeond
sudo systemctl restart palomad
