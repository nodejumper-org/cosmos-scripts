# Download binary
cd && wget https://github.com/warden-protocol/wardenprotocol/releases/download/${tag}/wardend_Linux_x86_64.zip
unzip wardend_Linux_x86_64.zip
rm -rf wardend_Linux_x86_64.zip
chmod +x wardend
sudo mv wardend $(which wardend)
