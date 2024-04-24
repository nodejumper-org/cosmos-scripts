cd && rm -rf omniflixhub
git clone https://github.com/Omniflix/omniflixhub.git
cd omniflixhub
git checkout v4.0.0
make install

sudo systemctl restart omniflixhubd
