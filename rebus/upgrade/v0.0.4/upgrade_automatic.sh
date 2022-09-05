#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

BLOCK=995737
VERSION="v0.0.4"
BINARY="rebusd"
CHEAT_SHEET="https://nodejumper.io/rebus-testnet/cheat-sheet"

printCyan "Your node will be upgraded to version: $VERSION on block height: $BLOCK" && sleep 1

for (( ; ; )); do
  height=$($BINARY status 2>&1 | jq -r .SyncInfo.latest_block_height)
  if ((height >= $BLOCK)); then
    source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/main/rebus/upgrade/$VERSION/upgrade_manual.sh)
    printCyan "Your node was successfully upgraded to version: $VERSION" && sleep 1
    bitcanna version --long | head
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
