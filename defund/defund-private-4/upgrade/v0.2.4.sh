sudo systemctl stop defundd

cd || return
rm -rf defund
git clone https://github.com/defund-labs/defund.git
cd defund || return
git checkout v0.2.4
make install
defundd version # 0.2.4

sudo systemctl start defundd