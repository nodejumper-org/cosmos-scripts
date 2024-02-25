# Download binary
cd $HOME && mkdir -p $HOME/go/bin
curl -L https://github.com/crossfichain/crossfi-node/releases/download/v${tag}/crossfi-node_${tag}_linux_amd64.tar.gz > crossfi-node_${tag}_linux_amd64.tar.gz
tar -xvzf crossfi-node_${tag}_linux_amd64.tar.gz
chmod +x $HOME/bin/crossfid
mv $HOME/bin/crossfid $HOME/go/bin
rm -rf crossfi-node_${tag}_linux_amd64.tar.gz $HOME/bin