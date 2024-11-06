# Clone consensus client repository
cd && rm -rf story
git clone https://github.com/piplabs/story.git
cd story
git checkout ${tag}

# Build consensus client binary
mkdir -p $HOME/go/bin/
go build -o $HOME/go/bin/story ./client

# Clone execution client repository
cd && rm -rf story-geth
git clone https://github.com/piplabs/story-geth.git
cd story-geth
git checkout v0.10.0

# Build execution client binary
make geth
mv build/bin/geth $HOME/go/bin/
