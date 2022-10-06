#!/bin/bash

# read arguments
while getopts n:v:s:h flag; do
  case "${flag}" in
  n) BINARY_NAME=$OPTARG ;;
  h) BINARY_HOME=$OPTARG ;;
  v) BINARY_VERSION=$OPTARG ;;
  s) SERVICE_NAME=$OPTARG ;;
  *) echo "WARN: unknown parameter: ${OPTARG}"
  esac
done

# install cosmovisor binary
COSMOVISOR_VERSION="v1.3.0"
if [ -z "$(which cosmovisor)" ]; then
  cd || return
  rm -rf cosmos-sdk
  git clone https://github.com/cosmos/cosmos-sdk
  cd cosmos-sdk || return
  git checkout "cosmovisor/$COSMOVISOR_VERSION"
  make cosmovisor
  mv cosmovisor/cosmovisor "$HOME/go/bin/cosmovisor"
fi

# setup directories
COSMOVISOR_DIR="$HOME/$BINARY_HOME/cosmovisor"
if [ -z "$BINARY_VERSION" ]; then
  mkdir -p "$COSMOVISOR_DIR/genesis/bin"
  cp "$(which $BINARY_NAME)" "$HOME/$BINARY_HOME/cosmovisor/genesis/bin"
  ln -s "$COSMOVISOR_DIR/genesis" "$COSMOVISOR_DIR/current"
else
  mkdir -p "$COSMOVISOR_DIR/upgrades/$BINARY_VERSION/bin"
  cp "$(which $BINARY_NAME)" "$HOME/$BINARY_HOME/cosmovisor/$BINARY_VERSION/bin"
  ln -s "$COSMOVISOR_DIR/upgrades/$BINARY_VERSION" "$COSMOVISOR_DIR/current"
fi

# update service file
sudo tee "/etc/systemd/system/$SERVICE_NAME.service" > /dev/null << EOF
[Unit]
Description=$BINARY_NAME Node Name
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=always
RestartSec=3
LimitNOFILE=10000
Environment="DAEMON_NAME=$BINARY_NAME"
Environment="DAEMON_HOME=$BINARY_HOME"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_LOG_BUFFER_SIZE=512"
Environment="UNSAFE_SKIP_BACKUP=true"

[Install]
WantedBy=multi-user.target
EOF

# reload service files
sudo systemctl daemon-reload
sudo systemctl restart $SERVICE_NAME
sudo journalctl -u $SERVICE_NAME -f -o cat --no-hostname
