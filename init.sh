#!/bin/sh
export HOME="$PWD/home"
export PATH="$PWD/opt/busybox:$PATH"
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
exec sh