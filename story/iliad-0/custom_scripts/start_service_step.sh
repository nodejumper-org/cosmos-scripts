# Create an execution client service
sudo tee /etc/systemd/system/story-geth.service > /dev/null << EOF
[Unit]
Description=Story Execution Client service
After=network-online.target

[Service]
User=$USER
WorkingDirectory=~
ExecStart=$HOME/go/bin/geth --iliad --syncmode full --http --ws
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable story-geth.service

# Start services and check the logs
sudo systemctl start story-geth.service
sudo systemctl start story.service

sudo journalctl -u story.service -f --no-hostname -o cat
