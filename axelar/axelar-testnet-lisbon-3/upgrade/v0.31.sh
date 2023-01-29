sudo systemctl stop axelard
sudo systemctl stop vald
sudo systemctl stop tofnd

cd || return
rm -rf axelar-core
git clone https://github.com/axelarnetwork/axelar-core.git
cd axelar-core || return
git checkout v0.31
make build
cp bin/axelard "$HOME/.axelar_testnet/bin/axelard"

sudo systemctl start axelard
sudo systemctl start vald
sudo systemctl start tofnd
