sudo systemctl stop haqqd

cd || return
rm -rf haqq
git clone https://github.com/haqq-network/haqq.git
cd haqq || return
git checkout v1.2.1
make install
haqqd version # 1.2.1

sudo systemctl restart haqqd