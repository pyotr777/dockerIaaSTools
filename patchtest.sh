#!/bin/bash

sshd_config_patch="sshd_config.patch"
diaasgroup="DIAS"
forcecommand="FC"
text="$(cat $sshd_config_patch)"
eval "cat <<$text" > tmp_$sshd_config_patch

