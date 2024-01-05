# Download binary
cd $HOME
curl -s https://storage.googleapis.com/pryzm-zone/core/0.10.0/pryzmd-0.10.0-linux-amd64.tar.gz > pryzmd-0.10.0-linux-amd64.tar.gz
tar -xzvf $HOME/pryzmd-0.10.0-linux-amd64.tar.gz
chmod +x pryzmd
mkdir -p $HOME/go/bin
mv pryzmd $HOME/go/bin