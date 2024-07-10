cd && rm -rf initia
git clone https://github.com/initia-labs/initia
cd initia
git checkout v0.2.23-stage-2
make build
sudo mv $HOME/initia/build/initiad $(which initiad)

sudo systemctl restart initiad
