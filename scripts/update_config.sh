#!/bin/sh
if [[ -z "$2" ]]; then exit 0; fi
sed -i .config -e "s#\($1=\).*#\1$2#g"