sudo systemctl stop omniflixhubd

cd || return
rm -rf omniflixhub
git clone https://github.com/Omniflix/omniflixhub.git
cd omniflixhub || return
git checkout v0.12.1
make install

sudo systemctl start omniflixhubd
