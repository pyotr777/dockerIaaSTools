#! /bin/bash

pythonscript="readconf.py"

val=$(python $pythonscript "${PWD}/conf_sample")

eval "$val"

echo "a=$a"
echo "timeout=$timeout"