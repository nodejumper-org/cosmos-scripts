# Create the client configuration file
echo -e 'chain-id = "${chainId}"\nkeyring-backend = "${keyringBackend}"\noutput = "text"\nnode = "tcp://localhost:${portPrefix}57"\nbroadcast-mode = "sync"' > $HOME/.union/config/client.toml