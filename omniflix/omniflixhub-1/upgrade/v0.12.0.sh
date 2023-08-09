sudo systemctl stop omniflixhubd

cd || return
rm -rf omniflixhub
git clone https://github.com/Omniflix/omniflixhub.git
cd omniflixhub || return
git checkout v0.12.0
make install
omniflixhubd version # 0.12.0

sudo systemctl start omniflixhubd
