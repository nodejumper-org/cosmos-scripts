sudo systemctl stop dewebd

dewebd unsafe-reset-all
rm $HOME/.deweb/config/genesis.json
sudo rm "$(which dewebd)"

cd
rm -rf deweb
git clone https://github.com/deweb-services/deweb.git
cd deweb
git checkout v0.3
make install
dewebd version # v0.3

dewebd config chain-id deweb-testnet-2
curl -s https://raw.githubusercontent.com/deweb-services/deweb/main/genesis.json > $HOME/.deweb/config/genesis.json
sed -E -i 's/seeds = \".*\"/seeds = \"08b7968ec375444f86912c2d9c3d28e04a5f14c4@seed1.deweb.services:26656\"/' $HOME/.deweb/config/config.toml
sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1false|" $HOME/.deweb/config/config.toml

sudo systemctl start dewebd
