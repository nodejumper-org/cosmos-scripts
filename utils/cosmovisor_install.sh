#!/bin/bash

while getopts v: flag; do
  case "${flag}" in
  v) VER=$OPTARG ;;
  *) echo "WARN: unknown parameter: ${OPTARG}"
  esac
done

version=${VER:-"v1.2.0"}

if [ -z "$(which cosmovisor)" ]; then
  cd || return
  rm -rf cosmos-sdk
  git clone https://github.com/cosmos/cosmos-sdk
  cd cosmos-sdk || return
  git checkout "cosmovisor/$version"
  make cosmovisor
  mv cosmovisor/cosmovisor $HOME/go/bin/cosmovisor
fi
