sudo systemctl stop kid

cd || return
rm -rf ki-tools
git clone https://github.com/KiFoundation/ki-tools.git
cd ki-tools || return
git checkout release/4.0.0
make install

sudo systemctl restart kid
