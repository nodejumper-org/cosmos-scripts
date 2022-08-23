sudo systemctl stop strided

cd || return
rm -rf stride
git clone https://github.com/Stride-Labs/stride.git
cd stride || return
git checkout 90859d68d39b53333c303809ee0765add2e59dab
make build
sudo cp build/strided $(which strided)

sudo systemctl restart strided
