# Download binary
cd $HOME
curl -s https://storage.googleapis.com/pryzm-zone/core/${tag}/pryzmd-${tag}-linux-amd64 > pryzmd
chmod +x pryzmd
mkdir -p $HOME/go/bin
mv pryzmd $HOME/go/bin