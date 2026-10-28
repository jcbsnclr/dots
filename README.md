# `dots` -- my Alpine Linux dotfiles

**NOTE:** Much of this was vibecoded. This is because I am lazy, *not* because
I am not well versed in Linux. You will see in the history of this repo that it
is not all vibe-coded, however using AI has helped me to find a number of issues
that I struggled to fix previously. Regardless, bare in mind that not all of this
has been written by me by hand.

Personal configuration for an Alpine Linux Wayland desktop built around
**labwc**, deployed with GNU Stow.

The host's full system reference lives in `~/docs/system/`:
`setup.typ` (desktop setup & dotfiles) and `system-overview.typ` (live system
audit). This README documents what each tracked file does and how it is
deployed.

## Layout

```text
dots/
├── deploy.sh              stow-based installer (targets: base | helix | desktop)
├── README.md              this file
├── LICENSE                MIT
├── .gitignore
├── ash/                   shell
│   ├── .profile           PATH + cargo env, sets ENV=~/.rc.sh
│   ├── .rc.sh             interactive-shell env & aliases
│   ├── .gitconfig         git identity + GPG signing
│   └── .tmux.conf         tmux keys/clipboard/history
├── gnupg/                 GPG agent config only (keys stay in ~/.gnupg)
│   └── .gnupg/gpg-agent.conf
├── helix/
│   └── .config/helix/     config.toml, languages.toml
├── scripts/
│   └── .local/bin/        host-agnostic scripts (stowed into ~/.local/bin)
├── desktop/
│   ├── .config/
│   │   ├── autostart/     org.keepassxc.KeePassXC.desktop
│   │   ├── fontconfig/    fonts.conf (Arabic fallback fix)
│   │   ├── gtk-2.0/       gtkfilechooser.ini
│   │   ├── gtk-3.0/       settings.ini (dir is real; only settings.ini stowed)
│   │   ├── gtk-4.0/       settings.ini (as above)
│   │   ├── kanshi/        display profiles (x1-carbon, ryzen-desktop)
│   │   ├── labwc/         autostart, environment, menu.xml, rc.xml, README
│   │   ├── mako/          notification daemon defaults
│   │   ├── mimeapps.list  xdg default applications
│   │   ├── rc/            openrc --user services: rc.conf, conf.d/, init.d/, runlevels/
│   │   ├── swayidle/      idle/lock/suspend rules
│   │   ├── user-dirs.dirs XDG user directories
│   │   ├── waybar/        config, style.css, scripts/iwd.sh
│   │   └── wlroots-mimeapps.list  PDF default
│   ├── .gtkrc-2.0         legacy GTK2 settings
│   ├── .local/bin/        desktop-only scripts
│   ├── .local/share/fonts/  APL386.ttf (public domain, not packaged by Alpine)
│   ├── .local/share/themes/gnoblin-labwc/
│   │   └── openbox-3/     dark window theme (themerc + titlebar XBMs)
│   └── .local/src/        wl-inhibit.c (idle-inhibitor helper source)
├── limine/                Limine bootloader config generator (not stowed)
│   ├── limine-gen         generator (generate | --mock | --check)
│   ├── limine-gen.conf    default /etc/conf.d/limine-gen
│   ├── 90-limine          apk post-commit hook
│   └── install.sh         one-shot root installer
└── attic/                 retired configs, kept for reference, NOT deployed
```

`$HOME` entries are symlinks into `dots/`, e.g. `.profile`, `.rc.sh`,
`.gitconfig`, `.tmux.conf`, `.gtkrc-2.0`, and most of `~/.config/*` (including
the whole `labwc`, `waybar`, `kanshi`, `swayidle` and `rc` directories).
`gtk-3.0`/`gtk-4.0` are the exception: those directories are real (they also
hold Breeze-generated CSS/assets), so only `settings.ini` is stowed. Likewise
`~/.local/share` and `~/.local/share/fonts` are real directories and only
`themes/gnoblin-labwc` and `fonts/APL386.ttf` are linked, so application data
and other fonts never land in the repo.
The `gnupg` package contains only `.gnupg/gpg-agent.conf` and is stowed with
`--no-folding`; the keyring itself stays in the real `~/.gnupg`.

## Install

```sh
./deploy.sh base       # shell, scripts, gpg-agent config
./deploy.sh helix      # helix only
./deploy.sh desktop    # base + helix + desktop (everything)
```

`deploy.sh` prints the packages, asks for confirmation, creates the real
directories apps write into (`~/.local/{bin,share,state}`, `~/.local/share/fonts`,
`~/.config/gtk-{3,4}.0`, `~/.config/helix`) so stow cannot fold them into the
repo, then runs
`stow --restow`; the `gnupg` package uses `--no-folding`. If a real file blocks
a link it offers `stow --adopt` (with a warning, since that copies live files
from `$HOME` into the repo). The `attic` package is never deployed.

## Package: `ash`

| File | What it does |
| ---- | ------------ |
| `.profile` | Adds `~/.local/bin` and `~/.opencode/bin` to `PATH`, sources `~/.cargo/env` when present, sets `ENV="$HOME/.rc.sh"` (ash reads it for interactive shells). |
| `.rc.sh` | Interactive shell setup: OSC terminal title, `EDITOR=hx`, `BROWSER=firefox`, `PAGER=less`, `MANPAGER=batman`, `GRIM_DEFAULT_DIR`, guarded `SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/keepass-ssh.sock"` (skipped in SSH sessions so agent forwarding works and no unlock dialog appears on the remote screen), `loginctl` power aliases, `doas`/`fp`/`git`/`exa` aliases, nightly Rust `PATH`. |
| `.gitconfig` | Git identity and GPG signing (`commit.gpgsign`, `tag.gpgSign`). |
| `.tmux.conf` | Prefix `M-Space` (+ `C-b`), system clipboard (`set-clipboard on`), base index 1, 100k history, mouse on, 1-line scroll, `M-v`/`M-b` splits, `M-c` window, `M-1..0` windows, `M-[`/`M-]` prev/next, `M-hjkl` panes, `M-f` zoom, `M-x` kill-pane confirm, no bell/activity. |

The front SSH socket in `.rc.sh` is the KeePassXC **unlock proxy**; see
`desktop/.local/bin/keepassxc-ssh-proxy` below.

## Package: `helix`

| File | What it does |
| ---- | ------------ |
| `config.toml` | `adwaita-dark` theme, relative line numbers, mouse, bufferline `multiple`, colour modes, true colour, rulers `[72, 80, 120]`, inline diagnostics, `tab`/`S-tab` switch buffers. |
| `languages.toml` | Typst via `tinymist` (`exportPdf = "never"`, soft-wrap, auto-pairs incl. `$`); C via `clangd` (`-header-insertion=never --clang-tidy`) + auto-format with `clang-format`; bash for `sh`/`openrc-run` shebangs. |

`hx` is built from `~/src/helix` (`cargo install --path helix-term --locked`,
toolchain pinned by its `rust-toolchain.toml`) and `.rc.sh` sets
`HELIX_RUNTIME=~/src/helix/runtime`, where the built grammars live.
`hx --grammar fetch`/`build` write to the first runtime directory,
`~/.config/helix/runtime`; move the resulting `grammars/*.so` into
`~/src/helix/runtime/grammars/` and delete that directory afterwards.
`~/.config/helix` is a real directory (only the two `.toml` files are
linked) so this never lands in the repo.

## Package: `scripts` (host-agnostic, `~/.local/bin`)

| Script | Purpose / deps |
| ------ | -------------- |
| `apkw` | Scrape and open the package homepage(s) from `apk info -w` in `$BROWSER`. |
| `batman` | Man pager: strip overstrikes with `sed` and pipe into `bat --language man` (`$MANPAGER`). |
| `clean-world` | Interactively walk `/etc/apk/world` and prune packages (`doas apk del --purge`). |
| `hxbak` | Copy a file to `*.bak`, then open it in `$EDITOR`. |
| `lorem` | Print N random English words (default 10); `aspell` + `python3`. |
| `mkscript` | Scaffold a script in `dots/scripts/.local/bin` and symlink it into `~/.local/bin`. |
| `mlo` | `mullvad relay set location <CODE> && mullvad reconnect`. |
| `newsboat-browser` | Newsboat URL dispatcher: YouTube (`www.`/`m.`/bare `youtube.com`, `youtu.be`) → `mpv`, everything else → `firefox`, with a `notify-send` toast. |
| `np-rss` | Convert a NewPipe subscriptions export into RSS URLs (adds the `youtube` tag); needs `jq`. |

## Package: `desktop`

### labwc (`~/.config/labwc`)

| File | Notes |
| ---- | ----- |
| `autostart` | user `gui` runlevel, `gsettings` dark colour scheme + cursor/icon theme (for GTK4/libadwaita and the settings portal), wallpaper (if present), guarded `SSH_AUTH_SOCK`/ssh-agent/`keepassxc-ssh-proxy`, launches `~/.config/autostart/*.desktop` via `gtk-launch`, updates the D-Bus activation env. |
| `environment` | Wayland hints (`MOZ_ENABLE_WAYLAND`, `SDL_VIDEODRIVER`, `_JAVA_AWT_WM_NONREPARENTING`), Qt (`QT_QPA_SYSTEM_ICON_THEME=Adwaita`, `QT_STYLE_OVERRIDE=adwaita-dark`), cursor (`capitaine-cursors-dark`, 24), keyboard `gb,ara` with `caps:none` + `grp:rctrl_toggle`. |
| `menu.xml` | Client menu (minimize/maximize/fullscreen/decorations/always-on-top/workspaces/close) and root menu (`apk upgrade` via `upgrade-helper`, suspend, power, reboot, firmware setup, exit). |
| `rc.xml` | Input: flat accel `pointerSpeed 0.5` (1.5x), numlock on, 10 desktops, theme `gnoblin-labwc` (radius 5, font `APL386 Unicode` 11), window rules (KeePassXC snapped centre; pinentry border + on top; polkit agent fully decorated + on top), custom regions + mousebinds, and all keybinds below. |
| `README` | Two-line pointer to `man labwc-config` / `man labwc-theme`. |

Keybinds (`W` = Super):

| Keys | Action |
| ---- | ------ |
| `W-1..0` / `W-S-1..0` | go to workspace / send window to workspace |
| `W-a`, `W-f` | toggle maximize / fullscreen |
| `A-Tab`, `A-S-Tab` | next / previous window |
| `W-Return`, `W-S-Return` | `foot`, `scratch-term` |
| `W-d`, `W-S-d` | `wmenu-run`, `fmenu` |
| `W-g`, `W-n` | focus/raise KeePassXC (or launch), `pkexec-id` |
| `W-p`, `W-S-p` | `pavucontrol-qt`, `qpwgraph` |
| `W-h/j/k/l`, `W-S-h/j/k/l`, `W-C-h/j/k/l` | move / grow / shrink to edge |
| `W-S-space` | grow to all edges |
| `W-KP_7..3`, `W-S-KP_*` | snap to region / region corner |
| `W-A-h/j/k/l`, `W-A-c` | snap to left/bottom/top/right half, centre (no-numpad) |
| `W-A-u/i/n/m`, `W-A-S-u/i/n/m` | snap to quadrant / quadrant corner (no-numpad) |
| `Print`, `S-Print`, `W-Print` | `scap all` / `output` / `area` |
| `W-s`, `W-S-s`, `W-S-o` | `scap area` / `all` / `output` (no PrintScreen key) |
| `XF86Audio*`, `XF86MonBrightness*` | `osd` volume/mic/brightness |
| `W-S-i`, `W-Escape` | `caffeine` (idle inhibit), `lock` |
| `W-q`, `W-S-q`, `W-S-c` | close, kill, reconfigure |

Mouse: `W-Left` drag move, `W-Right` drag resize, `W`+scroll resize,
titlebar scroll to shade, desktop scroll to switch workspace, desktop clicks
open `root-menu`.

### XDG defaults

- `.config/mimeapps.list`, `.config/wlroots-mimeapps.list` — default
  applications (Thunderbird for mail/calendar via the packaged
  `thunderbird.desktop`, so the IDs work on every host; sioyek for PDFs).
- `.config/user-dirs.dirs` — XDG directory layout used by `xdg-user-dir`.
- `.config/autostart/org.keepassxc.KeePassXC.desktop` — launched by the labwc
  autostart loop.

### waybar (`~/.config/waybar`)

- `config` — bottom dock, height 32, exclusive, reload styles on change.
  Left: `disk` (`/home` free space) + `wireplumber` (click → `pavucontrol-qt`);
  centre: `wlr/taskbar` (icon size 21, click activate, middle-click close,
  names truncated with `…`); right: `custom/iwd` (5 s poll, click → `iwgtk`),
  `battery` (warning 20 / critical 10), `tray`, `clock` (year-mode calendar
  tooltip).
- `style.css` — translucent dark palette (`bg_main rgba(25,25,25,0.65)`),
  `APL386 Unicode` 10pt, taskbar hover/active underlines, red disconnected
  iwd, amber/red battery states.
- `scripts/iwd.sh` — JSON status for `$IWD_IFACE` (default `wlan0`) from
  `iw dev … link` (SSID + dBm → 0–100 quality).

### kanshi, swayidle

- `kanshi/config` has one profile per machine; kanshi applies whichever
  matches the connected outputs:
  - `x1-carbon`: `eDP-1` at `3840x2400@60Hz`, position `0,0`, scale 2.
  - `ryzen-desktop`: Acer B247Y at `0,0` and Philips 227E6 at `1920,0`,
    both `1920x1080@60Hz`, matched by make/model/serial rather than port.
- `swayidle/config`:
  - 60 s: blank every output (`outputs off`, resume `outputs on`)
  - 120 s: `lock` (KeePassXC locks first, then `swaylock`)
  - 300 s: `loginctl suspend-then-hibernate`
  - before-sleep: `lock`
- `swayidle/config.<hostname>` overrides `config` on that host (picked by
  `rc/init.d/swayidle`). `config.ryzen-desktop` blanks and locks but never
  suspends, since the PC also serves files.

### User services (`openrc --user`, `~/.config/rc`)

- `rc.conf`: `rc_env_allow` (`HOME`, `WAYLAND_DISPLAY`, Qt vars, D-Bus,
  `XDG_RUNTIME_DIR`), parallel start, and the logger. `rc_log_path` is omitted
  so OpenRC's user-mode default (`$HOME/.local/state/rc.log`) is used.
- `init.d/`: `supervise-daemon` services, each logging to
  `~/.local/state/log/<name>.log`:
  `waybar` (after `wireplumber`), `swayidle` (after `dbus`), `wlsunset`
  (`-l ${LATITUDE} -L ${LONGITUDE}`), `mako` (after `dbus`),
  `lxqt-policykit-agent`.
- `conf.d/`: `wlsunset` (`LATITUDE=54.0`, `LONGITUDE=-1.7`), `kanshi`
  (commented logging option).
- `runlevels/`: `boot`/`shutdown` are empty; `default` links the system user
  services (`dbus`, `pipewire`, `pipewire-pulse`, `wireplumber`);
  `gui` pulls in `default` plus the repo services above and the system
  `kanshi`/`wlsunset`. Repo-owned links are relative (`../../init.d/...`);
  `/etc/user/init.d/*` links stay absolute.

### Theming

- `gtk-3.0/settings.ini`, `gtk-4.0/settings.ini`, `.gtkrc-2.0` — dark
  preference, `Adwaita` icons, `Noto Sans` 10, `capitaine-cursors-dark` 24,
  `ocean` sounds, `icon:minimize,maximize,close` decorations (GTK3/4).
- `fontconfig/fonts.conf` — pins `sans-serif` to `Noto Sans` first with
  `Noto Sans Arabic` next, ahead of Alpine's `58-noto.conf` preference for
  `Noto Sans Math`. Math covers Arabic codepoints but has no joining GSUB,
  so Firefox rendered Arabic as isolated letters; keeping `Noto Sans` first
  also keeps single-font consumers (cairo toy API, e.g. swaylock) working.
- `gtk-2.0/gtkfilechooser.ini` — path-bar location mode, size column, recent
  startup mode, window geometry.
- `.local/share/themes/gnoblin-labwc/openbox-3/` — dark labwc/openbox theme:
  `themerc` (active `#303030`, inactive `#242424`, 34 px titlebar, menus, OSD
  and window-switcher styling) plus hand-drawn titlebar XBMs.

### Desktop scripts (`~/.local/bin`)

| Script | Purpose / deps |
| ------ | -------------- |
| `bat%` | Battery charge + time left, mirroring the waybar module (same FA icons/colours); reads `/sys/class/power_supply/BAT*`, `upower` fallback for watts. |
| `caffeine` | Toggle a Wayland idle inhibitor (`wl-inhibit`) with OSD notifications; pauses swayidle lock/blank/hibernate. Requires `XDG_RUNTIME_DIR`; no `/tmp` fallback. |
| `colour-picker` | Copy one pixel's colour to the clipboard; `grim` + ImageMagick + `wl-copy` (optional geometry arg). |
| `discord-gamescope` | Launch the Discord Flatpak inside Gamescope, sized to the first enabled output (`wlr-randr --json` + `jq`, default 1920x1080); falls back to a plain launch. |
| `fmenu` | `.desktop` launcher: parses app dirs with `awk`, offers names via `wmenu`, launches with `gtk-launch`. |
| `keepassxc-ssh-proxy` | SSH agent proxy. Listens on `keepass-ssh.sock`, forwards to the real agent (`keepass-ssh-real.sock`); when ssh needs a key from a locked DB it raises KeePassXC (mako notification + `wlrctl`), waits up to 120 s for the unlock, then retries. Logs to `~/.local/state/log/keepassxc-ssh-proxy.log`; deps `wlrctl`, `notify-send`, `dbus-send`. |
| `lock` | `keepassxc --lock`, then `swaylock -f -c 000000`. |
| `outputs` | `off` disables every enabled output and remembers which; `on` re-enables them and runs `kanshictl reload` to restore the layout. Used by swayidle; needs `wlr-randr`. |
| `osd` | Media-key OSD via mako: `volume up/down/mute`, `mic mute`, `brightness up/down` (`wpctl`; `brightnessctl` when a backlight exists, otherwise `ddcutil` DDC/CI on external monitors, otherwise a "No backlight" notice; progress hint). |
| `upgrade-helper` | Root-menu "apk upgrade": opens `foot` running `doas apk upgrade -U` and waits for Enter. |
| `pkexec-gui` | `pkexec --disable-internal-agent` with stdio detached, so the polkit **GUI** agent prompts under Wayland. |
| `pkexec-id` | Test binding: `pkexec-gui /usr/bin/id`. |
| `scap` | Screenshot `all`/`area`/`output` → clipboard, timestamped PNG in `~/media/pictures/screenshots`, notification (`grim`/`slurp`/`wl-copy`). |
| `scratch-term` | Throwaway `foot` + `tmux` in a temp dir. |
| `wmenu`, `wmenu-run` | Wrappers forcing the Adwaita-dark palette on `wmenu`/`wmenu-run`. |
| `xdg-terminal-exec` | Minimal `xdg-terminal-exec`: runs `foot` (or `foot -e CMD`). |

`wl-inhibit` (a small Wayland idle-inhibitor) is built from
`desktop/.local/src/wl-inhibit.c`; the binary itself is not tracked:

```sh
cc -O2 -o ~/.local/bin/wl-inhibit desktop/.local/src/wl-inhibit.c \
   $(pkg-config --cflags --libs wayland-client)
```

### GPG (`gnupg/.gnupg/gpg-agent.conf`)

The keyring lives in the real `~/.gnupg`, outside this repo. Only
`gpg-agent.conf` (`pinentry-program /usr/bin/pinentry-qt`) is tracked, in a
separate `gnupg` package stowed with `--no-folding` so stow never folds the
directory into the repo. Keyrings, private keys, `random_seed`, and
revocation certificates are ignored via `.gitignore` and must never be
committed.

## Package: `attic` (not deployed)

Retired panel experiments, kept for reference:

- `sfwbar/` — GTK layer-shell bar: `sfwbar.config` plus variants
  (`oneline`, `twoline`, `t2`, `vertical`, `w10`, `wbar`), widgets (battery,
  clock, cpu, fan, memory, mpd, network, pulse, weather, usage, …) and the
  weather/misc icon sets. Driven by `sfwbar-watchdog` and `rc-init.d/sfwbar`.
- `wapanel/` — `wapanel.toml` (bottom panel: app-finder, task switcher, tray,
  volume, clock) and `rc-init.d/wapanel`.
- `rc-init.d/` — the OpenRC service scripts used by both, plus the disabled
  `wayvnc` service (loopback VNC with no authentication configured).

## Boot: Limine (`limine/`, not stowed)

Alpine-only Limine setup for UEFI machines (used on the X1 Carbon and on
`ryzen-desktop`; microcode is picked per CPU vendor). Requires the FAT ESP mounted
at `/boot` (Limine cannot read ext4/btrfs) and pairs every kernel under
`/lib/modules/*` with `/boot/vmlinuz-<flavour>` + `/boot/initramfs-<flavour>`
(the names mkinitfs uses).

- `limine-gen` — discovers every installed kernel (running flavour first),
  attaches `/boot/intel-ucode.img`/`amd-ucode.img` for the CPU vendor, and
  writes `/boot/EFI/limine/limine.conf` with BLAKE2b-512 checksums on kernel,
  ucode, and initramfs (needs `python3`), plus a checksum-less recovery entry
  per kernel and a GRUB chainload. Run as root; idempotent; logs to
  `/var/log/limine-gen.log`. It sets a fixed `PATH` before resolving tools.
  The checksums protect against corruption, not tampering or Secure Boot.
- `limine-gen --mock` — prints the config to stdout; no root, no writes
  (hashing still needs `python3`).
- `limine-gen --check` — diffs the installed config against a fresh one;
  uses `mktemp` for its temporary file.
- `limine-gen.conf` — defaults; installed to `/etc/conf.d/limine-gen` on first
  install and never overwritten afterwards.
- `90-limine` — apk commit hook (`/etc/apk/commit_hooks.d/90-limine`) that
  regenerates the config after kernel/mkinitfs/ucode/limine transactions.
  Manual `mkinitfs`/`update-kernel` runs need a manual `doas limine-gen`.
- `install.sh` — `doas ./limine/install.sh` (prompts before changing
  anything): installs `limine-tool` + `limine-efi-x86_64`, the files above,
  copies `BOOTX64.EFI` to the ESP, backs up the GRUB loader to
  `/boot/EFI/grub/grub-standalone.efi`, creates "Alpine Limine" + "Alpine GRUB
  (fallback)" EFI entries, and puts Limine first in `BootOrder`.
  Non-interactive runs require `--yes`; `--dry-run` prints every action
  without root or changes. It also requires the root-owned
  `/etc/conf.d/limine-gen` it installs.

Rollback: firmware boot menu (F12) → "Alpine GRUB (fallback)", then
`efibootmgr -o <old order>`. `/EFI/BOOT/BOOTX64.EFI` is left untouched.

Pin the kernel command line by setting `CMDLINE` in `/etc/conf.d/limine-gen`
after installing, so a one-off boot with edited options is never copied into
`limine.conf`. GRUB keeps its own command line in `/etc/default/grub`; keep
both in sync when boot options change (`grub-mkconfig -o /boot/grub/grub.cfg`
and `limine-gen`).

## Dependencies

Core desktop:

- GNU stow (deploy), labwc (wlroots), waybar, mako, kanshi, swaybg, swaylock,
  swayidle, foot, wmenu, `wl-clipboard`
- xdg-desktop-portal + xdg-desktop-portal-gtk, lxqt-policykit
- `wlrctl`, `libnotify`, `dbus` (`notify-send`/`dbus-send`) — SSH unlock proxy
- `keepassxc` with browser integration + SSH agent; `openssh`, `gnupg`
  (`pinentry-qt`)
- Fonts `APL386 Unicode` (shipped in `desktop/.local/share/fonts`) and
  `Font Awesome 7 Free` (`font-awesome`) (titles, bar, scripts)
- `wayland-client` headers only when building `wl-inhibit`

Per script (each checks its dependencies and fails clearly):

- `bat` + `less` — `batman`; `doas` — `clean-world`
- `grim`, `slurp`, `wl-clipboard`, ImageMagick — `scap`, `colour-picker`
- `jq` — `np-rss`; `aspell` + `python3` — `lorem`
- `newsboat`, `mpv`, `firefox` — `newsboat-browser`
- `flatpak` (and `gamescope` for GPU screen-share) — `fmenu`, `discord-gamescope`
- `wpctl` (pipewire), `brightnessctl` or `ddcutil`, `notify-send` — `osd`
- `foot`, `doas` — `upgrade-helper`
- `wlrctl`, `dbus-send`, `notify-send` — `keepassxc-ssh-proxy`
- `limine-tool`, `limine-efi-x86_64`, `python3` — `limine-gen`

## Notes

- Themes: Adwaita (dark) for GTK, Adwaita icons for Qt/GTK, dark
  `gnoblin-labwc` for windows, `capitaine-cursors-dark` cursor.
- `settings.ini` no longer carries KDE-generated `gtk-xft-dpi` or
  `gtk-modules` lines; scaling comes from the compositor output scale.
- `~/.local/bin` also contains locally built files (e.g. the `wl-inhibit`
  binary) alongside the stowed symlinks.
- GPG keyrings and `~/.ssh` are deliberately not tracked; the GPG keyring lives
  in `~/.gnupg` and only `gpg-agent.conf` is stowed.
- Clipboard history/persistence services were removed; copies are no longer
  retained on disk.
- The SSH unlock proxy, its socket layout and the KeePassXC key setup are
  described in `~/docs/system/system-overview.typ`.

## License

MIT -- see `LICENSE`.
