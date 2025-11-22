#!/usr/bin/env bash

eval "$(fzf --bash)"

############################################
###           General Functions          ###
############################################

# fd - cd to selected directory
function fd() {
    local dir
    # shellcheck disable=SC2086,SC2164
    dir=$(find ${1:-.} -path '*/\.*' -prune \
        -o -type d -print 2>/dev/null | fzf +m) &&
        cd "$dir"
}

# fdr - cd to selected parent directory
function fdr() {
    local dirs=()
    get_parent_dirs() {
        if [[ -d "${1}" ]]; then dirs+=("$1"); else return; fi
        if [[ "${1}" == '/' ]]; then
            for _dir in "${dirs[@]}"; do echo $_dir; done
        else
            get_parent_dirs $(dirname "$1")
        fi
    }
    local DIR=$(get_parent_dirs $(realpath "${1:-$PWD}") | fzf-tmux --tac)
    cd "$DIR"
}

# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
function fe() {
    local files
    IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
    [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

# fkill - kill process
function fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

    if [ "x$pid" != "x" ]; then
        echo $"pid" | xargs kill -$"{1:-9}"
    fi
}

# ftags - search ctags
function ftags() {
    local line
    [ -e tags ] &&
        line=$(
            awk 'BEGIN { FS="\t" } !/^!/ {print toupper($4)"\t"$1"\t"$2"\t"$3}' tags |
                cut -c1-80 | fzf --nth=1,2
        ) && ${EDITOR:-vim} $(cut -f3 <<<"$line") -c "set nocst" \
        -c "silent tag $(cut -f2 <<<"$line")"
}

# The following command uses fzf and apt to list all available packages, 
# allowing you to install a package by pressing the `Enter` key. 
# Here, fzf is used with the --preview option to show a preview pane 
# (in this case it shows the selected DEB package details)
function finstall_package() {
    apt-cache search '' | sort | cut --delimiter ' ' --fields 1 | \
    fzf --multi --cycle --reverse --preview 'apt-cache show {1}' | \
    xargs -r sudo apt install -y
}

############################################
###            Key-Bindings              ###
############################################

# Type Control-p to open interactive fzf search menu, and when Return is pressed,
# it'll open it in $EDITOR.
bind -x '"\C-p": $EDITOR $(fzf);'

############################################
###         Key-Bindings For Git         ###
############################################

function is_in_git_repo() {
  git rev-parse HEAD > /dev/null 2>&1
}

function fzf-down() {
  fzf --height 50% "$@" --border
}

function _gf() {
  is_in_git_repo || return
  git -c color.status=always status --short |
  fzf-down -m --ansi --nth 2..,.. \
    --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500' |
  cut -c4- | sed 's/.* -> //'
}

function _gb() {
  is_in_git_repo || return
  git branch -a --color=always | grep -v '/HEAD\s' | sort |
  fzf-down --ansi --multi --tac --preview-window right:70% \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -'$LINES |
  sed 's/^..//' | cut -d' ' -f1 |
  sed 's#^remotes/##'
}

function _gt() {
  is_in_git_repo || return
  git tag --sort -version:refname |
  fzf-down --multi --preview-window right:70% \
    --preview 'git show --color=always {} | head -'$LINES
}

function _gh() {
  is_in_git_repo || return
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  fzf-down --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always | head -'$LINES |
  grep -o "[a-f0-9]\{7,\}"
}

function _gr() {
  is_in_git_repo || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  fzf-down --tac \
    --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1} | head -200' |
  cut -d$'\t' -f1
}


# The following key-binding show different git objects with preview when
# possible.
# The key-binding are of form "\C-g\C-<Key>" which means:
# First press Ctrl-g, release and then press Ctrl-<Key>.

# This key-binding is (Alt-r) which should not be used by used and it's used 
# within the following key-bindings
# Note: redraw-current-line is not necessary if you're on tmux.
bind '"\er": redraw-current-line'

# Files that are modified or untracked (listed in `git status`).
bind '"\C-g\C-f": "$(_gf)\e\C-e\er"'

# Branches
bind '"\C-g\C-b": "$(_gb)\e\C-e\er"'

# Tags
bind '"\C-g\C-t": "$(_gt)\e\C-e\er"'

# Commit hashes
bind '"\C-g\C-h": "$(_gh)\e\C-e\er"'

# Rmotes
bind '"\C-g\C-r": "$(_gr)\e\C-e\er"'