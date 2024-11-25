cd && rm -rf bcna
git clone https://github.com/BitCannaGlobal/bcna.git
cd bcna
git checkout v4.0.1
make build

sudo mv build/bcnad $(which bcnad)

sudo systemctl restart bcnad
