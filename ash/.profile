export ENV=$HOME/.rc.sh

# pre-cache important directories 
# most important comes last
# fd . $HOME/src -tf -X readahead
# fd . $HOME/.local -tf -X readahead

export PATH="$HOME/.local/bin:$PATH"

# prayer-notify &

# if [[ -z $DISPLAY ]] && [[ "$(tty)" = /dev/tty1 ]]; then
#   if [[ -z "$XDG_RUNTIME_DIR"]]; then
#     XDG_RUNTIME_DIR="/tmp/$(id -u)-runtime-dir"
#     mkdir -pm 0700 "$XDG_RUNTIME_DIR"
#     export XDG_RUNTIME_DIR
#   fi
  
#   export XDG_SESSION_TYPE=wayland
#   export XDG_SESSION_DESKTOP=sway
#   export XDG_CURRENT_DESKTOP=sway

#   export MOZ_ENABLE_WAYLAND=1
#   export QP_QPA_PLATFORM=wayland
#   export SDL_VIDEODRIVER=wayland
#   export _JAVA_AWT_WM_NONREPARENTING=1

#   exec dbus-run-session sway
# fi

. "$HOME/.cargo/env"
