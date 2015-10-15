#!/bin/bash -x

sshd_config_patch="sshd_config.patch"
diaasgroup="DIAS"
forcecommand="FC"
text="$(echo EOF;cat $sshd_config_patch;echo EOF)"
eval "cat <<$text" > tmp_$sshd_config_patch

