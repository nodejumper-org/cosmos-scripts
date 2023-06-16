sudo systemctl stop agd

rm "$(which agd)"

cd || return
rm -rf agoric-sdk
git clone https://github.com/Agoric/agoric-sdk.git
cd agoric-sdk || return
git checkout mainnet1B-rc3
yarn install
yarn build
cd packages/cosmic-swingset || return
make build

ln -s $HOME/agoric-sdk/bin/agd $HOME/go/bin/agd

sudo systemctl start agd
