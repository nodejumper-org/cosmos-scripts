# Cosmos node config tool

### How to use
```
. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/node-installer/node_installer.sh) -c config.json
```

#### Config example - config.json
```
[
  {
    "installationScript": "https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/dev/installation-scripts/rizon_install.sh",
    "moniker": "nodejumper",
    "serviceName": "rizond",
    "chainId": "titan-1",
    "chainHomeDir": ".rizon",
    "minGasPrice": "0.0001uatolo",
    "stateSyncMode": false,
    "indexer": "null",
    "seeds": "83c9cdc2db2b4eff4acc9cd7d664ad5ae6191080@seed-1.mainnet.rizon.world:26656,ae1476777536e2be26507c4fbcf86b67540adb64@seed-2.mainnet.rizon.world:26656,8abf316257a264dc8744dee6be4981cfbbcaf4e4@seed-3.mainnet.rizon.world:26656",
    "peers": "0d51e8b9eb24f412dffc855c7bd854a8ecb3dff5@rpc1.nodejumper.io:26656",
    "ports": {
      "grpc": 9090,
      "grpcWeb": 9091,
      "proxyApp": 26658,
      "rpc": 26657,
      "pprof": 6060,
      "p2p": 26656,
      "prometheus": 26660
    },
    "tls": {
      "cert": "/path/to/cert.pem"
      "key": "/path/to/key.pem"
    }
  }
]
```
