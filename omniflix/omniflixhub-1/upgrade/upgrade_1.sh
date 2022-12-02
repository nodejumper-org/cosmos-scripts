sudo systemctl stop omniflixhubd

cd || return
rm -rf omniflixhub
git clone https://github.com/Omniflix/omniflixhub.git
cd omniflixhub || return
git checkout v0.8.0
make install
omniflixhubd version # 0.8.0

sudo systemctl restart omniflixhubd
