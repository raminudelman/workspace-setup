#!/usr/bin/env bash

##################################################
###                   Misc.                    ###
##################################################


# Enable aliases to be sudo’ed. Meaning allows calling sudo with aliases.
# For example: sudo my_alias.
# Without this alias, you will and error since my_alias is not a command.
alias sudo='sudo '

# Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitattributes | map dirname
alias map="xargs -n1"

# Print each PATH entry on a separate line
alias print_path='echo -e ${PATH//:/\\n}'

alias real_pwd='realpath -eL .'

alias print_linux_kernel_ver='uname -r'
alias print_hostname='uname -n' # Or simply run the command hostname

alias rm='rm -iv'
alias rmq='\rm -i'
alias cp='cp -iv'
alias mv='mv -iv'

alias c='clear'
alias h='history'
alias cs='clear;ll'

##################################################
###                    Grep                    ###
##################################################

# Always enable colored `grep` output
# Note: `GREP_OPTIONS="--color=auto"` is deprecated, hence the alias usage.
# Grep excluding the .git and .svn directories
alias grep='grep -E --colour=auto --exclude-dir="*\.{svn,git}"'
alias gerp='grep'
alias fgrep='fgrep --color=auto'

# Grep recursively through all files
alias grepall='grep -rn'

# Grep recursively through files with '.md' extension
alias grepmd='grep -r --include="*.md"' 

# Grep recursively in C/C++ projects excluding the .git and .svn directories
alias grepc='grep -rIn --color=auto --include=\*.{c,cpp,h} --exclude-dir="*\.{svn,git}" --exclude="*\tags"'

# Search history
alias gh='history|grep'

##################################################
###                   Utils                    ###
##################################################

alias untar='tar -zxvf'

# Use rsync to show progress bar
alias cpv='\rsync -a --human-readable --progress'
alias rsync="rsync --partial --progress --human-readable --compress"

##################################################
###                Permissions                 ###
##################################################

function wr() { # Add 'write' permissions to user
    local file=$1
    chmod u+w $file
}
function +w() { # Add 'write' permissions to user
    local file=$1
    chmod u+w $file
}
function ro() { # Make read-only (to all)
    local file=$1
    chmod a-w $file
}
function +x() { # Add 'execution' permissions to user
    local file=$1
    chmod u+x $file
}

##################################################
###      Files/Links/Directories listings      ###
##################################################

# Enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

# List files/directories
# -l  : use a long listing format
# -t  : sort by modification time, newest first
# -r  : reverse order while sorting
# -F  : append indicator (one of */=>@|) to entries
# -A  : do not list implied . and ..
# -h  : with -l and/or -s, print human readable sizes (e.g., 1K 234M 2G)
alias ll='ls -lFAh --group-directories-first'

# Sort by modified time (most recently modified will be in the bottom)
alias ltr='ll -tr'

# Sort by file/dir size
alias lls='ll -S' 

# Shows only directories
# The grep command greps all lines that start with the letter 'd'.
alias lld='ll --color=always | egrep --color=never "^d"' 

# Shows only links to files or to directories
# The grep command greps all lines that start with the letter 'l'.
alias lll='ll | egrep "^l"' 

# Shows only links to directories
# The grep command greps all lines that start with the letter 'l' and end 
# with the characters '/', and in between can be any amount of characters.
alias llld='ll | egrep "^l.*\/$"' 

# List only c/c++ source/header files 
alias llc="ll *.c *.cc"
alias llh="ll *.h"

# Show the sizes of all directories and files
alias du='du -h --max-depth 1'

##################################################
###                   Tmux                     ###
##################################################

# constructed with help from https://robots.thoughtbot.com/a-tmux-crash-course
alias t='tmux'

# Attach Tmux to last session (`a` is the short version of the long flag `attach`)
alias ta='tmux a'

# Detach Tmux current session (`d` is the short version of the long flag `detach`)
alias td='tmux d'

# Tmux list sessions: tls = tmux list-sessions
alias tls='tmux list-sessions'

# Tmux new session: tns [name] = tmux new session named [name]
alias tns='tmux new -s'

# Tmux detach all other clients
# See also:
# https://stackoverflow.com/questions/22138211/how-do-i-disconnect-all-other-users-in-tmux
alias tdetachothers='tmux detach-client -a'

# Tmux new window: tnw [name] = PREFIX + C
alias tnw='tmux new-window'

# Tmux attach window
# Two options for doing it:
# 1. `taw <number>` (simply type within the command line within a tmux session)
# 2. `PREFIX + <0-9>`
alias taw='tmux select-window -t'

# Tmux rename window
# Two options for doing it:
# 1. `trw <name>` (simply type within the command line within a tmux session)
# 2. `PREFIX + ,`
alias trw='tmux rename-window '

# Tmux vertical split window
alias tvsp='tmux split-window'

# Tmux horizontal split window
alias thsp='tmux split-window -h'

# Show my processes
alias pps="ps -aefF | egrep \"PID|${USER}\""

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

##################################################
###                    Git                     ###
##################################################

alias g="git"

# Navigate to the top level directory within the git repository
alias git_cg='cd `git rev-parse --show-toplevel`'

# Save the current work in a timestamped stash, without removing it.
alias git_snapshot='git stash save "snapshot: $(date)" && git stash apply "stash@{0}"'

