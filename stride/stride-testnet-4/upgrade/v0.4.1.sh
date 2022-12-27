sudo systemctl stop strided

cd $HOME/stride || return
git fetch
git checkout 90859d68d39b53333c303809ee0765add2e59dab
make build
sudo cp build/strided $(which strided)

sudo systemctl start strided
