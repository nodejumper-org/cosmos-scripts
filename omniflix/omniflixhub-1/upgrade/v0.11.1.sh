sudo systemctl stop omniflixhubd

cd || return
rm -rf omniflixhub
git clone https://github.com/Omniflix/omniflixhub.git
cd omniflixhub || return
git checkout v0.11.1
make install
omniflixhubd version # 0.11.1

sudo systemctl start omniflixhubd
