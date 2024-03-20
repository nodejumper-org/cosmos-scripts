# Clone project repository
cd $HOME && rm -rf wardenprotocol
git clone https://github.com/warden-protocol/wardenprotocol
cd  wardenprotocol
git checkout ${tag}

# Build binary
cd  warden/cmd/wardend
go build
mv wardend $HOME/go/bin