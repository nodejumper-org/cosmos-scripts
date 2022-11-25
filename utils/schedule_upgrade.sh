#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

while getopts n:i:t:v:b:c: flag; do
  case "${flag}" in
  n) CHAIN_NAME=$OPTARG ;;
  i) CHAIN_ID=$OPTARG ;;
  t) TARGET_BLOCK=$OPTARG ;;
  v) VERSION=$OPTARG ;;
  b) BINARY=$OPTARG ;;
  c) CHEAT_SHEET=$OPTARG ;;
  *) echo "WARN: unknown parameter: ${OPTARG}"
  esac
done

printLogo

echo -e "Your ${CYAN}$CHAIN_NAME${NC} node will be upgraded to version ${CYAN}$VERSION${NC} on block height ${CYAN}$TARGET_BLOCK${NC}" && sleep 1
echo ""

for (( ; ; )); do
  height=$($BINARY status 2>&1 | jq -r .SyncInfo.latest_block_height)
  if ((height >= TARGET_BLOCK)); then
    bash <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/${CHAIN_NAME,,}/$CHAIN_ID/upgrade/$VERSION.sh)
    printCyan "Your node was successfully upgraded to version: $VERSION" && sleep 1
    $BINARY version --long | head
    break
  else
    echo -e "Current block height: ${CYAN}$height${NC}"
  fi
  sleep 5
done

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
