ANSI_RED="$(tput setaf 1)"
ANSI_GREEN="$(tput setaf 2)"
ANSI_REGULAR="$(tput sgr0)"

# Set OSC0 for the terminal title.
# Taken from vte.sh
__osc_prompt_command() {
  local pwd='~'
  [ "$PWD" != "$HOME" ] && pwd=${PWD/#$HOME\//\~\/}
  printf "\[\033]0;%s@%s:%s\]" "${USER}" "${HOSTNAME%%.*}" "${PWD}" 
}

ps1_prompt_colour() {
  [ "$USER" = "root" ] && echo "\[$ANSI_RED\]" || echo "\[$ANSI_GREEN\]"
}

ps1_prompt_char() {
  [ "$USER" = "root" ] && echo "#" || echo "\$"
}

export PS1='$(__osc_prompt_command)$(ps1_prompt_colour)[\u@\h \w]\[$ANSI_REGULAR\] $(ps1_prompt_char) '

export EDITOR=hx
export BROWSER=firefox

# export GTK_THEME=Adwaita:dark
# export QT_STYLE_OVERRIDE=Adwaita-Dark

export PAGER=less
export MANPAGER=batman

export GRIM_DEFAULT_DIR=$HOME/media/pictures/screenshots

FP="$(which flatpak)"

# power management aliases
alias reboot="loginctl reboot"
alias poweroff="loginctl poweroff"
alias zzz="loginctl suspend"

# misc
alias monrl="wlr-randr --output DP-3 --on --output DP-1 --on"

# interactive and verbose aliases
alias cp="cp -iv"
alias rm="rm -iv"
alias mkdir="mkdir -v"
alias mv="mv -iv"
alias dfree="df -h"
alias tree="exa --tree --long"
alias pg="pgrep"
alias nb="newsboat"
alias chx="chmod +x"
alias chux="chmod u+x"

alias ex="dtrx"
alias fm="pcmanfm-qt"

# packagae management
alias fp-add="doas $FP install --system"
alias fp-del="doas $FP uninstall --system"
alias fp-upd="doas $FP update --system"
alias fp-run="$FP run"

# navigation
alias aports="cd $HOME/aports"
alias src="cd $HOME/src"
alias down="cd $HOME/net/down"
alias docs="cd $HOME/docs"
alias pictures="cd $HOME/media/pictures"
alias videos="cd $HOME/media/videos"
alias music="cd $HOME/media/music"
alias dots="cd $HOME/dots"

alias ..="cd .."
alias ..2="cd ../.."
alias ..3="cd ../../.."

# aliases for doas
alias hxas="doas hx"
alias rmas="doas rm -iv"
alias cpas="doas cp -iv"
alias mvas="doas mv -iv"
alias mkdiras="doas mkdir -v"
alias chownas="doas chown"
alias chmodas="doas chmod"
alias chxas="doas chmod +x"
alias chuxas="doas chmod u+x"

# generic aliases
alias bat="bat --color=always"
alias lsa="ls -lsah"

# git aliases
alias gbr="git branch"
alias gps="git push"
alias gpl="git pull"
alias gcm="git commit"
alias gst="git status"
alias gdf="git diff"
alias gad="git add"
alias grm="git rm"
alias gck="git checkout"
alias glg="git log"

alias gls="exa --long --git --git-ignore"
alias gtree="exa --tree --git --git-ignore --long --no-user -a"

alias make="make -j12"

# service management aliases
alias rc-add="doas rc-update add"
alias rc-del="doas rc-update del"
alias rc-st="rc-status"
alias sv="doas rc-service"

alias urc-add="rc-update add --user"
alias urc-del="rc-update del --user"
alias urc-st="rc-status --user"
alias usv="rc-service --user"

alias vpn-on="doas rc-service wg-quick.se-sto-wg-001 start"
alias vpn-off="doas rc-service wg-quick.se-sto-wg-001 stop"

# launch gui
alias gui="labwc-run"

alias msc="meson compile -C build/"
alias mst="meson test -C build/"
alias mss="meson setup build/"

alias os="jack_oscrolloscope -d 0.1 -s -f 100"

if [ "$USER" != "root" ]; then
  export PATH="$HOME/.rustup/toolchains/nightly-x86_64-unknown-linux-musl/bin:$PATH"
fi
