# Cosmos node config tool

### How to use

#### Config example - config.json
```
[
  {
    "moniker": "jumper",
    "chainId": "galaxy-1",
    "chainHomePath": "/home/jumper/.galaxy",
    "minGasPrice": "0.001uglx",
    "stateSyncMode": false,
    "indexer": "null",
    "seeds": "",
    "peers": "",
    "ports": {
      "grpc": "9090",
      "grpcWeb": "9091",
      "proxyApp": "26658",
      "rpc": "26657",
      "pprof": "6060",
      "p2p": "26656",
      "prometheus": "26660"
    },
    "tsl": {
      "cert": "/path/to/cert.pem"
      "key": "/path/to/key.pem"
    }
  }
]
```
#### Run command
```
./configure_node.sh -c config.json
```
