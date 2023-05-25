sudo systemctl stop ununifid

cd || return
rm -rf ununifi
git clone https://github.com/UnUniFi/chain ununifi
cd ununifi || return
git checkout v2.0.0
make install
ununifid version # HEAD-1880753e670dde5cde5bf9bb8b26647dd91c8f89

sudo systemctl start ununifid
