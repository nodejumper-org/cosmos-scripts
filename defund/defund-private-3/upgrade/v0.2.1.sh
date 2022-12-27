sudo systemctl stop defundd

cd || return
rm -rf defund
git clone https://github.com/defund-labs/defund.git
cd defund || return
git checkout v0.2.1
make install
defundd version # 0.2.1

sudo systemctl start defundd