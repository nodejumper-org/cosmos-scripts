cd || return
cd stride || return
git fetch
git checkout 4ec1b0ca818561cef04f8e6df84069b14399590e
make build
sudo cp $HOME/stride/build/strided $HOME/go/bin
strided version #v0.3.1

sudo systemctl restart strided
sudo journalctl -u strided -f --no-hostname -o cat