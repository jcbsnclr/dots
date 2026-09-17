# `dots` -- my Alpine Linux dotfiles

Personal configuration for a Wayland desktop built around **labwc**, deployed
with GNU Stow.

## Layout

| Package   | Installs                                                             |
| --------- | -------------------------------------------------------------------- |
| `ash`     | shell: `.profile`, `.rc.sh`, `.tmux.conf`                            |
| `helix`   | Helix editor config                                                   |
| `scripts` | host-agnostic scripts in `~/.local/bin`                              |
| `desktop` | Wayland desktop: labwc, waybar, GTK, kanshi, user `rc` services, desktop-only scripts, `gnoblin-labwc` theme |
| `attic`   | retired configs, kept for reference and **not** deployed             |

## Install

```sh
./deploy.sh base       # shell + scripts
./deploy.sh helix      # helix only
./deploy.sh desktop    # base + helix + desktop (everything)
```

`deploy.sh` uses `stow --restow`. If a real file blocks a link it offers
`stow --adopt` to pull that file into the repo.

## Dependencies

Core:

- GNU stow
- labwc (wlroots), waybar, mako, kanshi, swaybg, swaylock
- xdg-desktop-portal + xdg-desktop-portal-gtk
- lxqt-policykit, pinentry-qt
- `APL386 Unicode` and `Font Awesome 6 Free` fonts (window titles + bar)

Optional, per script (each script checks and exits with a clear error):

- `bat` + `less` -- `batman` man pager (falls back to `sed` if `col` is absent)
- `grim`, `slurp`, `wl-clipboard`, ImageMagick -- `scap`, `colour-picker`
- `jq` -- `np-rss`
- `aspell` + `python3` -- `lorem`
- `newsboat`, `mpv`, `firefox` -- `newsboat-browser`
- `wmenu`, `flatpak` -- `fmenu`
- `foot`, `tmux` -- `scratch-term`
- `doas` -- `clean-world`

## Notes

- User services run under `openrc --user`; see `desktop/.config/rc`.
- Theme: Breeze for GTK, Adwaita icons for Qt, dark `gnoblin-labwc` for windows,
  `capitaine-cursors-dark` cursor.
- `attic/` holds retired panel configs (sfwbar, wapanel).

## License

MIT -- see `LICENSE`.
