# upgrade paloma
cd && rm -rf paloma
git clone -b v2.1.2 https://github.com/palomachain/paloma.git
cd paloma
make build
sudo mv -f build/palomad "$(which palomad)"

sudo systemctl restart palomad