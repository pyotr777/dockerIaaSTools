#!/bin/bash

ip addres show $1 | grep 'inet 172.' | awk '{ print $2 }'
