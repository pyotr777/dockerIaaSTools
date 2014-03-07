#!/bin/bash
str1=${@/-oForwardAgent=no/-oForwardAgent=yes};
str2=${str1/-oClearAllForwardings=yes/};
eval "/usr/bin/ssh $str2"
