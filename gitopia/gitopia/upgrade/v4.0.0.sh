cd && rm -rf gitopia
git clone https://github.com/gitopia/gitopia.git
cd gitopia
git checkout v4.0.0
make install

sudo systemctl restart gitopiad
