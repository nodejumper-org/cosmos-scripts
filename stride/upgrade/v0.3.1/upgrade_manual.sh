sudo systemctl stop strided

cd || return
cd stride || return
git fetch
git checkout 4ec1b0ca818561cef04f8e6df84069b14399590e
make build
mkdir -p $HOME/go/bin
sudo cp $HOME/stride/build/strided $HOME/go/bin

sudo systemctl restart strided