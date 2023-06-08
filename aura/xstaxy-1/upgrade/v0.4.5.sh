sudo systemctl stop aurad

cd || return
rm -rf aura
git clone https://github.com/aura-nw/aura
cd aura || return
git checkout aura_v0.4.5
make install

sudo systemctl start aurad
