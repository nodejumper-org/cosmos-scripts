#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

BLOCK=155420
VERSION=v0.3.1
BINARY=strided

printCyan "Your node will be upgraded to version: $VERSION on block height: $BLOCK" && sleep 1

for (( ; ; )); do
  height=$($BINARY status |& jq -r ."SyncInfo"."latest_block_height")
  if ((height >= $BLOCK)); then

    source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/stride/upgrade/v0.3.1/upgrade_manual.sh)

    for ((timer = 60; timer > 0; timer--)); do
      printCyan "Restarting for the second time after 60s" && sleep 1
    done
    height=$($BINARY status |& jq -r ."SyncInfo"."latest_block_height")
    if ((height > $BLOCK)); then
      printCyan "Your node was successfully upgraded to version: $VERSION" && sleep 1
    fi
    strided version --long | head
    break
  else
    echo $height
  fi
  sleep 1
done

printLine
printCyan "Check logs:            sudo journalctl -u $BINARY -f --no-hostname -o cat"
printCyan "Check synchronization: $BINARY status 2>&1 | jq .SyncInfo.catching_up"
printCyan "More commands:         $CHEAT_SHEET"
