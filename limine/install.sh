#!/bin/sh
# install.sh -- install limine-gen and the Limine bootloader on Alpine.
#
# Usage:
#   doas ./limine/install.sh          # install (prompts before changes)
#   doas ./limine/install.sh --yes    # install without prompting
#   ./limine/install.sh --dry-run     # print the actions, change nothing
#
# What it does:
#   1. apk add limine-tool limine-efi-x86_64 (+ efibootmgr/python3 if missing)
#   2. install limine-gen, /etc/conf.d/limine-gen, apk commit hook
#   3. copy BOOTX64.EFI to /boot/EFI/limine/
#   4. back up the current GRUB loader for chainloading
#   5. create a separate "Alpine Limine" EFI entry (+ GRUB fallback entry)
#   6. generate limine.conf and put Limine first in BootOrder
#
# GRUB is left installed; /EFI/BOOT/BOOTX64.EFI and /boot/grub are untouched.
# Override disk/partition autodetection with DISK=/dev/nvme0n1 PART=1.
set -eu

src=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

dry=no
assume_yes=no
case "${1:-}" in
	--dry-run | -n) dry=yes ;;
	--yes | -y) assume_yes=yes ;;
	--help | -h)
		sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
		exit 0
		;;
	'') ;;
	*)
		echo "usage: install.sh [--dry-run] [--yes]" >&2
		exit 2
		;;
esac

run() {
	if [ "$dry" = yes ]; then
		printf '  [dry-run] %s\n' "$*" >&2
	else
		"$@"
	fi
}

if [ "$dry" != yes ] && [ "$(id -u)" -ne 0 ]; then
	echo "install.sh: run as root (doas ./limine/install.sh) or use --dry-run" >&2
	exit 1
fi

boot_fstype=$(awk '$2 == "/boot" { print $3 }' /proc/mounts)
[ "$boot_fstype" = vfat ] || {
	echo "install.sh: /boot is ${boot_fstype:-not a mount point}, expected vfat" >&2
	exit 1
}

boot_dev=$(awk '$2 == "/boot" { print $1 }' /proc/mounts)
pkname=$(lsblk -dno PKNAME "$boot_dev" 2>/dev/null | head -n1)
if [ -n "${DISK:-}" ]; then
	disk=$DISK
elif [ -n "$pkname" ]; then
	disk=/dev/$pkname
else
	disk=$boot_dev
fi
part=${PART:-$(cat "/sys/class/block/${boot_dev##*/}/partition" 2>/dev/null || true)}
if [ -z "$part" ]; then
	part=$(lsblk -no PARTN "$boot_dev" 2>/dev/null | head -n1 || true)
fi
if [ ! -b "$disk" ] || [ -z "$part" ]; then
	echo "install.sh: cannot determine the disk/partition of $boot_dev; set DISK= and PART=" >&2
	exit 1
fi

missing=""
command -v efibootmgr >/dev/null 2>&1 || missing="$missing efibootmgr"
command -v python3 >/dev/null 2>&1 || missing="$missing python3"
if [ ! -f /usr/share/limine/BOOTX64.EFI ]; then
	missing="$missing limine-tool limine-efi-x86_64"
fi
if [ -n "$missing" ]; then
	echo "==> installing packages:$missing"
	run apk add $missing
fi

efi_src=""
for f in /usr/share/limine/BOOTX64.EFI /usr/share/limine/BOOTX64.efi; do
	if [ -f "$f" ]; then
		efi_src=$f
		break
	fi
done
if [ -z "$efi_src" ]; then
	if [ "$dry" = yes ]; then
		echo "  [dry-run] Limine EFI binary not installed yet; assuming /usr/share/limine/BOOTX64.EFI" >&2
		efi_src=/usr/share/limine/BOOTX64.EFI
	else
		echo "install.sh: BOOTX64.EFI not found (apk add limine-efi-x86_64)" >&2
		exit 1
	fi
fi

if [ "$dry" = yes ]; then
	echo "==> dry-run: printing actions only; nothing will be changed"
elif [ "$assume_yes" = yes ]; then
	:
elif [ -t 0 ]; then
	cat >&2 <<EOF

About to:
  - install limine-gen + apk commit hook + /etc/conf.d/limine-gen
  - install the Limine EFI binary to /boot/EFI/limine/BOOTX64.EFI
  - back up the GRUB loader to /boot/EFI/grub/grub-standalone.efi
  - create EFI entries "Alpine Limine" and "Alpine GRUB (fallback)"
  - generate /boot/EFI/limine/limine.conf
  - put "Alpine Limine" first in BootOrder (GRUB entries stay)

Proceed? [y/N] 
EOF
	read -r ans || ans=""
	case "${ans:-n}" in
		[Yy]*) ;;
		*) echo "install.sh: aborted" >&2; exit 1 ;;
	esac
else
	echo "install.sh: refusing non-interactive run without --yes" >&2
	exit 1
fi

echo "==> installing files"
run install -Dm755 "$src/limine-gen" /usr/local/sbin/limine-gen
run install -Dm755 "$src/90-limine" /etc/apk/commit_hooks.d/90-limine
if [ ! -e /etc/conf.d/limine-gen ]; then
	run install -Dm644 "$src/limine-gen.conf" /etc/conf.d/limine-gen
fi

echo "==> installing Limine EFI binary"
run mkdir -p /boot/EFI/limine
run install -m644 "$efi_src" /boot/EFI/limine/BOOTX64.EFI

grub_fallback=no
if [ -f /boot/EFI/grub/grub-standalone.efi ]; then
	grub_fallback=yes
elif [ -f /boot/EFI/boot/bootx64.efi ]; then
	echo "==> backing up current GRUB loader to /boot/EFI/grub/grub-standalone.efi"
	run install -Dm644 /boot/EFI/boot/bootx64.efi /boot/EFI/grub/grub-standalone.efi
	grub_fallback=yes
fi

ensure_entry() {
	label=$1
	loader=$2
	num=$(efibootmgr -v 2>/dev/null | sed -n "s/^Boot\([0-9A-Fa-f]\{4\}\).*$label.*/\1/p" | head -n1)
	if [ -n "$num" ]; then
		printf '%s' "$num"
		return 0
	fi
	if [ "$dry" = yes ]; then
		printf '  [dry-run] efibootmgr --create --disk %s --part %s --label "%s" --loader "%s"\n' \
			"$disk" "$part" "$label" "$loader" >&2
		printf 'DRY'
		return 0
	fi
	echo "==> creating EFI entry: $label" >&2
	if ! efibootmgr --create --disk "$disk" --part "$part" --label "$label" --loader "$loader" >/dev/null; then
		echo "install.sh: efibootmgr failed to create entry: $label" >&2
		exit 1
	fi
	num=$(efibootmgr -v 2>/dev/null | sed -n "s/^Boot\([0-9A-Fa-f]\{4\}\).*$label.*/\1/p" | head -n1)
	if [ -z "$num" ]; then
		echo "install.sh: entry '$label' not found after creation" >&2
		exit 1
	fi
	printf '%s' "$num"
}

if [ "$grub_fallback" = yes ]; then
	ensure_entry "Alpine GRUB (fallback)" '\EFI\grub\grub-standalone.efi' >/dev/null
fi
limine_num=$(ensure_entry "Alpine Limine" '\EFI\limine\BOOTX64.EFI')
case "$limine_num" in
	[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]) ;;
	DRY)
		[ "$dry" = yes ] || {
			echo "install.sh: unexpected EFI entry number '$limine_num'" >&2
			exit 1
		}
		;;
	*)
		echo "install.sh: failed to create the Limine EFI entry" >&2
		exit 1
		;;
esac

echo "==> generating limine.conf"
run /usr/local/sbin/limine-gen

order=$(efibootmgr 2>/dev/null | sed -n 's/^BootOrder: //p')
new_order=$limine_num
old_ifs=$IFS
IFS=,
for n in $order; do
	[ "$n" = "$limine_num" ] && continue
	new_order="$new_order,$n"
done
IFS=$old_ifs

if [ "$order" != "$new_order" ]; then
	echo "==> setting BootOrder: $new_order"
	if ! run efibootmgr -o "$new_order" >/dev/null; then
		echo "install.sh: efibootmgr failed to set BootOrder" >&2
		exit 1
	fi
fi

if [ "$dry" != yes ]; then
	first=$(efibootmgr 2>/dev/null | sed -n 's/^BootOrder: \([^,]*\).*/\1/p')
	if [ "$first" = "$limine_num" ]; then
		echo "==> BootOrder starts with $limine_num (Limine)"
	else
		echo "install.sh: warning: BootOrder starts with '$first', expected '$limine_num'" >&2
	fi
fi

if [ "$dry" = yes ]; then
	printf '\nDry run complete: no changes were made.\n'
else
	cat <<EOF

Done. Limine is installed and first in the boot order.

Verify before rebooting:
  /usr/local/sbin/limine-gen --check
  cat /boot/EFI/limine/limine.conf
  efibootmgr

Rollback:
  firmware boot menu (F12) -> "Alpine GRUB (fallback)"
  efibootmgr -o $order
EOF
fi
