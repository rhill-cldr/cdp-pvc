#!/usr/bin/env bash
case $1 in
    --list) pyhocon -i $ANSIBLE_INVENTORY/hgx.conf -f json;;
    --host) python3 src/util/ansible_host_vars.py $2;;
esac




