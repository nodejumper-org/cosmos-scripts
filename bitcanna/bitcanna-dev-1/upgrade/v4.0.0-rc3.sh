cd && rm -rf bcna
git clone https://github.com/BitCannaGlobal/bcna.git
cd bcna
git checkout v4.0.0-rc3
make install

sudo systemctl restart bcnad
