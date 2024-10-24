# Initialize the node
story init --moniker ${moniker} --network iliad

# Add seeds
sed -i -e "s|^seeds *=.*|seeds = \"${seeds}\"|" $HOME/.story/story/config/config.toml

# Make geth directory
mkdir -p $HOME/.story/geth
