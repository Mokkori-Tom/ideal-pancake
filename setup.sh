#!/bin/sh
export HOME="$PWD/root"  # 先に必ず設定
export OPT="$PWD/opt"
# $HOME/.profile
# ここでシェル起動
exec sh --login # https://frippery.org/busybox/
# >busybox64.exe sh setup.sh
