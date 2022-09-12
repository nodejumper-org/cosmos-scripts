#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

BLOCK=5113000
VERSION="v0.4.0"
BINARY="rizond"
CHEAT_SHEET="https://nodejumper.io/rizon/cheat-sheet"

printCyan "Your node will be upgraded to version: $VERSION on block height: $BLOCK" && sleep 1

for (( ; ; )); do
  height=$($BINARY status 2>&1 | jq -r .SyncInfo.latest_block_height)
  if ((height >= $BLOCK)); then
    source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/main/rizon/upgrade/$VERSION/upgrade_manual.sh)
    printCyan "Your node was successfully upgraded to version: $VERSION" && sleep 1
    $BINARY version --long | head
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
