echo -e 'chain-id = "${chainId}"\n\
keyring-backend = "${keyringBackend}"\n\
output = "text"\n\
node = "tcp://localhost:${rpcPort}"\n\
broadcast-mode = "sync"' > $HOME/.union/config/client.toml