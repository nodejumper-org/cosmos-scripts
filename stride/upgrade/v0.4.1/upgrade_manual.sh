sudo systemctl stop strided

cd || return
rm -rf stride
git clone https://github.com/Stride-Labs/stride.git
cd stride || return
git checkout 90859d68d39b53333c303809ee0765add2e59dab
make build
mkdir -p $HOME/go/bin
sudo cp $HOME/stride/build/strided $HOME/go/bin

sudo systemctl restart strided
