sudo systemctl stop soarchaind

curl -s https://raw.githubusercontent.com/soar-robotics/testnet-binaries/main/v0.2.8/ubuntu22.04/soarchaind > soarchaind
chmod +x soarchaind
sudo mv -f soarchaind "$(which soarchaind)"

sudo systemctl start soarchaind
