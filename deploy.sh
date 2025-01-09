#!/usr/bin/env bash
sed -i '/metal.*$/d' $HOME/.ssh/known_hosts
ROOT=$(pwd)
TF=$ROOT/src/main/opentf/ssb_base
cd $TF
terraform apply
cd $ROOT
ansible-runner run runner -p metal.yml
echo $CM_URL


