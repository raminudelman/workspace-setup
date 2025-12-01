#!/usr/bin/env bash

############################################
###                 TMUX                 ###
############################################

# check if terminal is running
GNOME_TERMINAL_PID=$(pgrep gnome-terminal)
GNOME_TERMINAL_IS_RUNNING=false

# The regular expression ^[0-9]+$ will match a non-empty contiguous string of
# digits, i.e. a non-empty line that is composed of nothing but digits. 
# Using this regular expression in [[ ... =~ there ]] in bash 3.2 or above, 
# should be unquoted, i.e. ^[0-9]+$ instead of '^[0-9]+$'.
# if [[ $GNOME_TERMINAL_PID =~ ^[0-9]+$ ]]; then
#     # switch to it
#     GNOME_TERMINAL_IS_RUNNING=true
#     #echo "GNOME terminal is already running"
# fi

# Start tmux on every (graphical) shell login and try to attach to the default
# session specified by `DEFAULT_TMUX_SESSION`
#
# Note:
# * `[ -x "$(command -v tmux)" ]` - Checks if tmux is available in the system
# * `[ -n "${DISPLAY}" ]`         - Checks if a a graphical session is running 
#                                   (remove this condition if you want tmux to
#                                   start in any login shell, but it might
#                                   interfere with auto-starting X at login).
# * `[ -z "${TMUX}" ]`            - Checks if we are not already inside a tmux session
#
# * `[ -z "${NO_TMUX}" ]`         - Checks if we have in the ENV the NO_TMUX env var set (used in some script like open-in-terminal.sh)
DEFAULT_TMUX_SESSION="main"
if [ -x "$(command -v tmux)" ] && [ -n "${DISPLAY}" ] && [ -z "${TMUX}" ] && [ -z "${NO_TMUX}" ] && ${GNOME_TERMINAL_IS_RUNNING}; then
    tmux attach -t ${DEFAULT_TMUX_SESSION} || tmux new-session -s ${DEFAULT_TMUX_SESSION} >/dev/null 2>&1
fi
