#!/usr/bin/env sh
# deploy.sh -- stow the dotfiles packages into $HOME.

set -eu

msg() { echo "$@" 1>&2; }
die() { msg "$@"; exit 1; }

usage() {
	die "usage: $(basename "$0") <base|helix|desktop>"
}

command -v stow >/dev/null 2>&1 || die "error: GNU stow not found"
command -v tput >/dev/null 2>&1 || die "error: tput not found"

BOLD=$(tput bold)
CYAN=$(tput setaf 6)
NORMAL=$(tput sgr0)

yesno() {
	while true; do
		printf '%s%s?%s [y/N]: ' "$BOLD" "$CYAN$1" "$NORMAL"
		read -r tmp

		case "${tmp:-n}" in
		[Yy]*) ANS=y; return 0 ;;
		[Nn]* | '') ANS=n; return 0 ;;
		*) echo "please answer yes or no" 1>&2 ;;
		esac
	done
}

TARGET=${1:-}
[ -n "$TARGET" ] || usage

DEPS=""
add() { DEPS="$DEPS $1"; }

base() { add ash; add scripts; }
helix() { add helix; }
desktop() { base; helix; add desktop; }

case "$TARGET" in
base) base ;;
helix) helix ;;
desktop) desktop ;;
*) die "unknown target '$TARGET'" ;;
esac

msg "$(tput bold)to install:$(tput sgr0)"
printf '\t%s\n' "$DEPS" 1>&2

yesno "install config files"

if [ "$ANS" = y ]; then
	for dep in $DEPS; do
		if ! stow --restow "$dep"; then
			yesno "run stow --adopt for $dep"

			if [ "$ANS" = y ]; then
				stow --restow --adopt "$dep"
			fi
		fi
	done
fi
