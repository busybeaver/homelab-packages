#!/bin/bash

# SNAP_DATA is backed up and restored across snap refresh and snap revert operations
"$SNAP/bin/consul" agent -config-dir="$SNAP_DATA/config/"
