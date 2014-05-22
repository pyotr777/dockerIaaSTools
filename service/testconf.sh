#! /bin/bash

pythonscript="readconf.py"

val=$(python $pythonscript conf_sample)

eval "$val"

echo "a=$a"
echo "timeout=$timeout"