sudo systemctl stop aurad

rm -rf $HOME/.aura/wasm/wasm/cache

cd || return
rm -rf aura
git clone https://github.com/aura-nw/aura
cd aura || return
git checkout aura_v0.4.5
make install

sudo systemctl start aurad
