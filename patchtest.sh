#!/bin/bash

isshd_config_patch="sshd_config.patch"
diaasgroup="DIAS"
forcecommand="FC"
cp "$sshd_config_patch" "tmp_$sshd_config_patch"
sed -i "s/\$diaasgroup/$diaasgroup/" "tmp_$sshd_config_patch"
sed -i "s/\$forcecommand/$forcecommand/" "tmp_$sshd_config_patch"
