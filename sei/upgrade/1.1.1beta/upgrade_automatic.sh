#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

BLOCK=3223245
VERSION="1.1.1beta"
BINARY="seid"
CHEAT_SHEET="https://nodejumper.io/sei-testnet/cheat-sheet"

printCyan "Your node will be upgraded to version: $VERSION on block height: $BLOCK" && sleep 1

for (( ; ; )); do
  height=$($BINARY status 2>&1 | jq -r .SyncInfo.latest_block_height)
  if ((height >= $BLOCK)); then
    bash <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/main/sei/upgrade/$VERSION/upgrade_manual.sh)
    printCyan "Your node was successfully upgraded to version: $VERSION" && sleep 1
    strided version --long | head
    break
  else
    echo "Current block height: $height"
  fi
  sleep 5
done

printLine
printCyan "Check logs:            sudo journalctl -u $BINARY -f --no-hostname -o cat"
printCyan "Check synchronization: $BINARY status 2>&1 | jq .SyncInfo.catching_up"
printCyan "More commands:         $CHEAT_SHEET"
