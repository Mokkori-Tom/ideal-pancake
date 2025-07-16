#!/bin/sh
export HOME="$PWD"  # 先に必ず設定
export OPT="$HOME/../../opt"

# ここでシェル起動
exec sh --login # https://frippery.org/busybox/
