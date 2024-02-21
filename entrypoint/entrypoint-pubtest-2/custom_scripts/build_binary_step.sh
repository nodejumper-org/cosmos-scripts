# Download binary
cd $HOME
curl -s https://github.com/entrypoint-zone/testnets/releases/download/v${tag}/entrypointd-${tag}-linux-amd64 > entrypointd
chmod +x soarchaind
mkdir -p $HOME/go/bin/
mv entrypointd $HOME/go/bin/