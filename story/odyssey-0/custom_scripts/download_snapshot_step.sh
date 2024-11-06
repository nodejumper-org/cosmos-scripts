# Download latest chain data snapshot
curl "https://snapshots-testnet.nodejumper.io/story/story_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.story/story"
curl "https://snapshots-testnet.nodejumper.io/story/story_latest_geth.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.story/geth"
