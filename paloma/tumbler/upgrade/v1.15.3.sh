# upgrade paloma
cd && rm -rf paloma
git clone -b v1.15.3 https://github.com/palomachain/paloma.git
cd paloma
make build
sudo mv -f build/palomad "$(which palomad)"

# upgrade pigeon
cd && rm -rf pigeon
git clone -b v1.12.3 https://github.com/palomachain/pigeon
cd pigeon
make build
sudo mv -f build/pigeon "$(which pigeon)"

sudo systemctl restart pigeond
sudo systemctl restart palomad
