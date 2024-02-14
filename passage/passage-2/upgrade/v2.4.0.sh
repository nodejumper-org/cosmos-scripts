sudo systemctl stop passage

cd || return
rm -rf Passage3D
git clone https://github.com/envadiv/Passage3D
cd Passage3D || return
git checkout v2.4.0
make install

sudo systemctl start passage
