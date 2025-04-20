#!/usr/bin/env sh

msg() {
  echo $@ 1>&2
}

die() {
  msg $@
  exit 1
}

if [ "$#" -ne 1 ]; then
  die "usage: ./deploy.sh [TARGET]"
elif ! which stow >/dev/null; then
  die "error: GNU stow not found"
elif ! which tput >/dev/null; then
  die "error: tput not found"
fi

BOLD=$(tput bold)
CYAN=$(tput setaf 6)
NORMAL=$(tput sgr0)

yesno() {
  while true; do
    read -p "$BOLD$CYAN$1?$NORMAL [y/N]: " tmp

    if [ -z "$tmp" ]; then 
      ANS=n
      break
    fi
    
    case $tmp in 
      [Yy]* ) ANS=y; break;;
      [Nn]* ) ANS=n; break;;
          * ) echo "please answer yes or no" 1>&2 ;;
      
    esac
  done
}

TARGET=$1

DEPS=""

case "$TARGET" in
  main)
    DEPS="ash desktop scripts helix" 
    ;;

  sh)
    DEPS="ash scripts helix"
    ;;
  
  *)
    die "unknown target '$TARGET'"
esac

msg "$(tput bold)to install:$(tput sgr0)"
msg -e "\t$DEPS"

yesno "install config files"

if [ "$ANS" = "y" ]; then
  for dep in $DEPS; do
    # stow $dep
    if ! stow $dep; then
      yesno "run stow adopt"

      if [ "$ANS" = "y" ]; then
        stow $dep --adopt
      fi
    fi
  done
fi
