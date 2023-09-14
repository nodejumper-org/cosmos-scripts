# stop node service
sudo systemctl stop banksyd

cd $HOME || return
rm -rf gitopia
git clone https://github.com/gitopia/gitopia.git
cd gitopia || return
git checkout v3.0.0
make install

# start node service
sudo systemctl start centaurid
