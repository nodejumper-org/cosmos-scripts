sudo systemctl stop aurad

rm -rf $HOME/.aura/wasm/wasm/cache

cd && rm -rf aura
git clone https://github.com/aura-nw/aura
cd aura
git checkout v0.9.3
make install

sudo systemctl start aurad
