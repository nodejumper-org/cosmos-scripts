# install docker

# create dirs
mkdir -p $HOME/hyperbridge-data/data

# run hyperbridge node
docker run -d \
  --name=hyperbridge \
  --restart=always \
  -p 9944:9944 \
  -v $HOME/hyperbridge-data/data:/data \
  polytopelabs/hyperbridge:latest  \
  --chain=gargantua \
  --name=NODEJUMPER

# create configs
ETHERSCAN_API_KEY=
BASESCAN_API_KEY=
BSCCSAN_API_KEY=

ETH_RPC=https://rpc.sepolia.org
ARBITRUM_RPC=https://sepolia-rollup.arbitrum.io/rpc
OPTIMISM_RPC=https://sepolia.optimism.io
BASE_RPC=https://sepolia.base.org
BSC_RPC=http://109.230.208.238:8545

SIGNER_PK=

sudo tee $HOME/hyperbridge-data/config.toml > /dev/null << EOF
# Hyperbridge config, required
[hyperbridge]
# Hyperbridge chain spec, either one of Dev, Gargantua, Messier or Nexus
chain = "Gargantua" # testnet
# Hyperbidge node ws rpc endpoint.
rpc_ws = "ws://127.0.0.1:9944" # example endpoint

[ethereum]
# configuration type
type = "ethereum_sepolia"
# State machine identifier
state_machine = { Ethereum = "ExecutionLayer" }
# http(s) rpc url for sepolia
rpc_url = "$ETH_RPC"
# consensus state identifier for sepolia on hyperbridge
consensus_state_id = "ETH0"
# etherscan api key for querying Ethereum token price
etherscan_api_key = "$ETHERSCAN_API_KEY"
# Contract address of the HandlerV1 contract
handler = "0xF763D969aDC8281b1A8459Bde4CE86BA811b0Aaf"
# Contract address of the IsmpHost contract
ismp_host = "0xe4226c474A6f4BF285eA80c2f01c0942B04323e5"
# hex-encoded private key for the relayer
signer = "$SIGNER_PK"

[arbitrum]
# configuration type
type = "arbitrum"
# State machine identifier
state_machine = { Ethereum = "Arbitrum" }
# http(s) rpc url for arbitrum
rpc_url = "$ARBITRUM_RPC"
# consensus state identifier for arbitrum on hyperbridge, L2s use ethereum as their consensus oracle
consensus_state_id = "ETH0"
# etherscan api key for querying Ethereum token price
etherscan_api_key = "$ETHERSCAN_API_KEY"
# Contract address of the HandlerV1 contract
handler = "0x5cD7935ffE0942f6fF05D447A1325109510DD846"
# Contract address of the IsmpHost contract
ismp_host = "0x56101AD00677488B3576C85e9e75d4F0a08BD627"
# hex-encoded private key for the relayer
signer = "$SIGNER_PK"

[optimism]
# configuration type
type = "optimism"
# State machine identifier
state_machine = { Ethereum = "Optimism" }
# http(s) rpc url for optimism
rpc_url = "$OPTIMISM_RPC"
# consensus state identifier for optimism on hyperbridge, L2s use ethereum as their consensus oracle
consensus_state_id = "ETH0"
# etherscan api key for querying Ethereum token price
etherscan_api_key = "$ETHERSCAN_API_KEY"
# Contract address of the HandlerV1 contract
handler = "0x8738b27E29Af7c92ba2AF72B2fcF01C8934e3Db0"
# Contract address of the IsmpHost contract
ismp_host = "0x39f3D7a7783653a04e2970e35e5f32F0e720daeB"
# hex-encoded private key for the relayer
signer = "$SIGNER_PK"

[base]
# configuration type
type = "base"
# State machine identifier
state_machine = { Ethereum = "Base" }
# http(s) rpc url for base
rpc_url = "$BASE_RPC"
# consensus state identifier for base on hyperbridge, L2s use ethereum as their consensus oracle
consensus_state_id = "ETH0"
# etherscan api key for querying Ethereum token price
etherscan_api_key = "$BASESCAN_API_KEY"
# Contract address of the HandlerV1 contract
handler = "0x0B26ba93424A7d00153abEb6388C55F960529E89"
# Contract address of the IsmpHost contract
ismp_host = "0x1D14e30e440B8DBA9765108eC291B7b66F98Fd09"
# hex-encoded private key for the relayer
signer = "$SIGNER_PK"

[bsc]
# configuration type
type = "bsc"
# State machine identifier
state_machine = "Bsc"
# http(s) rpc url for binance smart chain
rpc_url = "$BSC_RPC"
# consensus state identifier for binance smart chain on hyperbridge
consensus_state_id = "BSC0"
# etherscan api key for querying BNB token price
etherscan_api_key = "$BSCCSAN_API_KEY"
# Contract address of the HandlerV1 contract
handler = "0x3aBA86C71C86353e5a96E98e1E08411063B5e2DB"
# Contract address of the IsmpHost contract
ismp_host = "0x4e5bbdd9fE89F54157DDb64b21eD4D1CA1CDf9a6"
# hex-encoded private key for the relayer
signer = "$SIGNER_PK"

# Relayer config, required
[relayer]
# Hyperbridge chain spec, either one of Dev, Gargantua, Messier or Nexus
chain = "Gargantua" # testnet
# Define your profitability configuration. 0 -> 0% i.e relay all requests, even unprofitable ones. 1 -> 1%. ie fees provided for requests must be profitable by at least 1%. etc.
minimum_profit_percentage = 1
# (Optional) If not empty, will filter requests to be delivered by originating module identifier (eg contract address)
module_filter = []
# (Optional) If not empty, only deliver to the specied state-machines
delivery_endpoints = [
    { Ethereum = "ExecutionLayer" },
    { Ethereum = "Arbitrum" },
    { Ethereum = "Optimism" },
    { Ethereum = "Base" },
    "Bsc"
]
EOF

# run relayer
docker run -d \
  --name=tesseract \
  --network=host \
  --restart=always \
  --volume=$HOME/hyperbridge-data:/home/root \
  polytopelabs/tesseract:latest \
  --config=/home/root/config.toml \
  --db=/home/root/dev.db

# accumulate fees (stop any relayer before running this command)
docker run \
  --network=host \
  -v $HOME/hyperbridge-data:/home/root \
  polytopelabs/tesseract:latest \
  --config=/home/root/config.toml \
  --db=/home/root/dev.db \
  accumulate-fees

# withdraw fees (stop any relayer before running this command)
docker run \
  --network=host \
  -v $HOME/hyperbridge-data:/home/root \
  polytopelabs/tesseract:latest \
  --config=/home/root/config.toml \
  --db=/home/root/dev.db \
  accumulate-fees --withdraw
