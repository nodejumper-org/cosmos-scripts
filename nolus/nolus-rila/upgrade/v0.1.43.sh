sudo systemctl stop nolusd

cd || return
rm -rf nolus-core
git clone https://github.com/Nolus-Protocol/nolus-core.git
cd nolus-core || return
git checkout v0.1.43
make install
nolusd version # 0.1.43

sudo systemctl start nolusd
