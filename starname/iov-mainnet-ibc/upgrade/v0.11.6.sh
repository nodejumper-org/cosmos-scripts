sudo systemctl stop starnamed

rm -rf starnamed
git clone https://github.com/iov-one/starnamed.git
cd starnamed || return
git checkout tags/v0.11.6
make build
mkdir -p $HOME/go/bin
sudo cp $HOME/starnamed/build/starnamed $HOME/go/bin
starnamed version # v0.11.6

sudo systemctl restart starnamed