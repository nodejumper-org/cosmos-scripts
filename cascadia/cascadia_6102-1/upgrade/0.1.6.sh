sudo systemctl stop cascadiad

curl -L https://github.com/CascadiaFoundation/cascadia/releases/download/v0.1.6/cascadiad -o cascadiad
chmod +x cascadiad
sudo mv cascadiad /usr/local/bin

sudo systemctl start cascadiad
