#!/usr/bin/env sh
# deploy.sh -- stow the dotfiles packages into $HOME.

set -eu

CDPATH= cd -- "$(dirname -- "$0")" || exit 1

msg() { echo "$@" 1>&2; }
die() { msg "$@"; exit 1; }

usage() {
	die "usage: $(basename "$0") <base|helix|desktop>"
}

command -v stow >/dev/null 2>&1 || die "error: GNU stow not found"
command -v tput >/dev/null 2>&1 || die "error: tput not found"

BOLD=$(tput bold 2>/dev/null || true)
CYAN=$(tput setaf 6 2>/dev/null || true)
NORMAL=$(tput sgr0 2>/dev/null || true)

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

base() { add ash; add scripts; add gnupg; }
helix() { add helix; }
desktop() { base; helix; add desktop; }

stow_pkg() {
	local dep
	dep=$1
	shift

	case "$dep" in
	gnupg) stow --target="$HOME" --no-folding "$@" "$dep" ;;
	*) stow --target="$HOME" "$@" "$dep" ;;
	esac
}

# --adopt overwrites tracked files in the repo with whatever is in $HOME, so
# refuse to run it when that would discard uncommitted or untracked work.
repo_dirty() {
	command -v git >/dev/null 2>&1 || return 1
	git rev-parse --git-dir >/dev/null 2>&1 || return 1
	[ -n "$(git status --porcelain --untracked-files=normal)" ]
}

case "$TARGET" in
base) base ;;
helix) helix ;;
desktop) desktop ;;
*) die "unknown target '$TARGET'" ;;
esac

msg "${BOLD}to install:${NORMAL}"
printf '\t%s\n' "$DEPS" 1>&2

yesno "install config files"

if [ "$ANS" = y ]; then
	# real directories that apps write into; stow must not fold them into
	# the repo on a fresh $HOME
	mkdir -p "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.local/state" \
		"$HOME/.local/state/log" "$HOME/.local/share/fonts" \
		"$HOME/.config/helix" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

	for dep in $DEPS; do
		if ! stow_pkg "$dep" --restow; then
			if repo_dirty; then
				die "error: $dep needs --adopt but the repo has uncommitted changes; commit or stash them first"
			fi

			msg "warning: --adopt copies live files from \$HOME into the repo."
			yesno "run stow --adopt for $dep"

			if [ "$ANS" = y ]; then
				stow_pkg "$dep" --restow --adopt
			fi
		fi
	done
fi
