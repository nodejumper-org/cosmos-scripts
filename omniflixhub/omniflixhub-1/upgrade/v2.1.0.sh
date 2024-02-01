sudo systemctl stop omniflixhubd

cd || return
rm -rf omniflixhub
git clone https://github.com/Omniflix/omniflixhub.git
cd omniflixhub || return
git checkout v2.1.0
make install

sudo systemctl start omniflixhubd
