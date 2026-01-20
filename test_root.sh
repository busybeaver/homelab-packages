#!/usr/bin/env bash
if [[ $EUID -ne 0 ]]; then
  echo "Not root: $EUID"
else
  echo "Root: $EUID"
fi
