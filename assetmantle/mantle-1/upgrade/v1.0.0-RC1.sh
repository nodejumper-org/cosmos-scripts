sudo systemctl stop mantleNode

cd || return
rm -rf node
git clone https://github.com/AssetMantle/node.git
cd node || return
git checkout v1.0.0-RC1
make install

sudo systemctl start mantleNode
