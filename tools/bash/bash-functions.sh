#!/usr/bin/env bash

function path_remove() {
    [ -d "$1" ] || return

    # Handles the case where PATH contains this only path to remove
    if [ "$PATH" == "$1" ] ; then PATH="" ; fi

    # Delete path by parts so we can never accidentally remove sub paths
    PATH=${PATH//":$1:"/":"} # delete any instances in the middle
    PATH=${PATH/#"$1:"/} # delete any instance at the beginning
    PATH=${PATH/%":$1"/} # delete any instance in the at the end
    export PATH
}

function path_add_to_start() {
    [ -d "$1" ] || return
    path_remove "$1"
    export PATH="$1:$PATH"
}

function path_add_to_end() {
    [ -d "$1" ] || return
    path_remove "$1"
    export PATH="$PATH:$1"
}

function path_add_to_start_force() {
    path_remove "$1"
    export PATH="$1:$PATH"
}

# Finds files/directories recursively within the current directory
function findf() {
    find . -name "$@"
    # find only files
    # find . -type f -name "$@"
}

# Find all files (recursively) within the provided directory and sort them
# according to the modification data
function find_last_modified() {
    find "$1" -type f -printf '%TY.%Tm.%Td %P\n' | sort
}

# Create a new directory and enter it
function mkcd() {
    mkdir -p "$@" && cd "$_"
}
export -f mkcd


# Determine size of a file or total size of a directory
function fs() {
    if du -b /dev/null >/dev/null 2>&1; then
        local arg=-sbh
    else
        local arg=-sh
    fi
    if [[ -n "$@" ]]; then
        du $arg -- "$@"
    else
        du $arg .[^.]* ./*
    fi
}

# Use Git's colored diff when available
function gitdiff() {
    git diff --no-index --color-words "$@"
}

function gitdiffdir() {
    DATE=`date +%F_%H-%M-%S`
    # .diff files can be open in BeyondCompare in a side-by-side view
    git diff --output="git_${DATE}.diff" --diff-algorithm=patience "$@"
}

function diffdir() {
    local src=$1
    local dst=$2
    local esc=$(printf '\033')

    diff --brief --recursive ${src} ${dst} | \
        # The command 
        #    sed 's/and//'
        #    Replaces the word "and" with nothing (e.g. removes the word)
        sed 's/and//'                      | \
        # The command 
        #    sed 's/Files/Diff/'
        #    Replaces the word "Files" with the word "Diff"
        sed 's/Files/Diff/'                | \
        # The command 
        #    sed "s,Diff,${esc}[31m&${esc}[0m,"
        #    Changes the word "Diff" into red color
        sed "s,Diff,${esc}[31m&${esc}[0m," | \
        # The command 
        #    sed "s,Only,${esc}[32m&${esc}[0m,"
        #    Changes the word "Only" into green color
        sed "s,Only,${esc}[32m&${esc}[0m,"
}


# `tre` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
function tre() {
    tree -aC -I '.git' --dirsfirst "$@" | less -FRNX
}

# Help with extractions
function extract() {
    if [ -f "$1" ]; then
        case "$1" in
        *.tar.bz2) tar xvjf "$1" ;;
        *.tar.gz) tar xvzf "$1" ;;
        *.bz2) bunzip2 "$1" ;;
        *.rar) unrar x "$1" ;;
        *.gz) gunzip "$1" ;;
        *.tar) tar xvf "$1" ;;
        *.tbz2) tar xvjf "$1" ;;
        *.tgz) tar xvzf "$1" ;;
        *.zip) unzip "$1" ;;
        *.Z) uncompress "$1" ;;
        *.7z) 7z x "$1" ;;
        *) echo "don't know how to extract '$1'..." ;;
        esac
    else
        echo "'$1' is not a valid file!"
    fi
}

# SSH to the given machine and add your id_rsa.pub or id_dsa.pub to authorized_keys.
#
#     henrik@Nyx ~$ sshkey hyper
#     Password:
#     sshkey done.
#
function sshkey() {
    ssh $1 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys" <~/.ssh/id_?sa.pub # '?sa' is a glob, not a typo!
    echo "sshkey done."
}

# Attach or create a tmux session.
#
# You can provide a name as the first argument, otherwise it defaults to the current directory name.
# The argument tab completes among existing tmux session names.
#
# Example usage:
#
#   tat some-project
#
#   tat s<tab>
#
#   cd some-project
#   tat
#
# Based on https://github.com/thoughtbot/dotfiles/blob/master/bin/tat
# and http://krauspe.eu/r/tmux/comments/25mnr7/how_to_switch_sessions_faster_preferably_with/
#
function tat() {
    session_name=$(basename ${1:-$PWD})
    session_name=${session_name/auctionet_/an_}
    session_name=${session_name/\./_}
    tmux new-session -As "$session_name"
}

function _tmux_complete_session() {
    local IFS=$'\n'
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=(${COMPREPLY[@]:-} $(compgen -W "$(tmux -q list-sessions | cut -f 1 -d ':')" -- "${cur}"))
}
complete -F _tmux_complete_session tat

# Call from a local repo to open the repository on github/bitbucket in browser
# Modified version of https://github.com/zeke/ghwd
function repo() {
    # Figure out github repo base URL
    local base_url
    base_url=$(git config --get remote.origin.url)
    base_url=${base_url%\.git} # remove .git from end of string

    # Fix git@github.com: URLs
    base_url=${base_url//git@github\.com:/https:\/\/github\.com\/}

    # Fix git://github.com URLS
    base_url=${base_url//git:\/\/github\.com/https:\/\/github\.com\/}

    # Fix git@bitbucket.org: URLs
    base_url=${base_url//git@bitbucket.org:/https:\/\/bitbucket\.org\/}

    # Fix git@gitlab.com: URLs
    base_url=${base_url//git@gitlab\.com:/https:\/\/gitlab\.com\/}

    # Validate that this folder is a git folder
    if ! git branch 2>/dev/null 1>&2; then
        echo "Not a git repo!"
        return $?
    fi

    # Find current directory relative to .git parent
    full_path=$(pwd)
    git_base_path=$(
        cd "./$(git rev-parse --show-cdup)" || return 1
        pwd
    )
    relative_path=${full_path#$git_base_path} # remove leading git_base_path from working directory

    # If filename argument is present, append it
    if [ "$1" ]; then
        relative_path="$relative_path/$1"
    fi

    # Figure out current git branch
    # git_where=$(command git symbolic-ref -q HEAD || command git name-rev --name-only --no-undefined --always HEAD) 2>/dev/null
    git_where=$(command git name-rev --name-only --no-undefined --always HEAD) 2>/dev/null

    # Remove cruft from branchname
    branch=${git_where#refs\/heads\/}

    [[ $base_url == *bitbucket* ]] && tree="src" || tree="tree"
    url="$base_url/$tree/$branch$relative_path"

    echo "Calling $(type open) for $url"

    open "$url" &>/dev/null || (echo "Using $(type open) to open URL failed." && return 1)
}
export -f repo

# Get colors in manual pages
function man() {
    env \
        LESS_TERMCAP_mb="$(printf '\e[1;31m')" \
        LESS_TERMCAP_md="$(printf '\e[1;31m')" \
        LESS_TERMCAP_me="$(printf '\e[0m')" \
        LESS_TERMCAP_se="$(printf '\e[0m')" \
        LESS_TERMCAP_so="$(printf '\e[1;44;33m')" \
        LESS_TERMCAP_ue="$(printf '\e[0m')" \
        LESS_TERMCAP_us="$(printf '\e[1;32m')" \
        man "$@"
}

# Find distro
function print_distro() {
    local os=$(cat /etc/os-release | grep ^NAME | cut -d'"' -f2)
    if [[ $os == "CentOS Linux" ]]; then
        local centos_distro=$(print_centos_distro)
        echo "${os} - ${centos_distro}"
    elif [[ $os == "Ubuntu" ]]; then
        local ubuntu_distro=$(print_pretty_name_distro)
        echo "${os} - ${ubuntu_distro}"
    elif [[ $os == "Red Hat Enterprise Linux Server" ]]; then
        local rhel_distro=$(print_pretty_name_distro)
        echo "${os} - ${rhel_distro}"
    elif [[ ${os} == "Fedora Linux" ]]; then
	local fedora_distro=$(print_pretty_name_distro)
        echo "${os} - ${fedora_distro}"
    else
        echo "*** Error - could not find the distro!"
        return
    fi
}
export -f print_distro

# Find CentOS distro
function print_centos_distro() {
    echo $(cat /etc/redhat-release | awk '{print $4}')
}
export -f print_centos_distro

# Find the "Pretty Name" of the distro
function print_pretty_name_distro() {
    echo $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2-)
}
export -f print_pretty_name_distro

# Bash show function (BSF)
function bsf() {
    local function_to_show=$1

    #echo "Greping for '${function_to_show}() {'"

    # -F used find the exact string
    # -n used to show the line number
    local file=$(grep -nF "function ${function_to_show}() {" ${HOME}/.bash* | cut -d":" -f1)
    local line_number=$(grep -nF "function ${function_to_show}() {" ${HOME}/.bash* | cut -d":" -f2)
    less -N +${line_number} ${file}
}
export -f bsf

# Function to find where an alias is defined
function my_alias() {
    local alias_to_find=$1

    local file=$(grep -nF "function ${alias_to_find}() {" ${HOME}/.bash* | cut -d":" -f1)
    local line_number=$(grep -nF "function ${alias_to_find}() {" ${HOME}/.bash* | cut -d":" -f2)
    echo "Checking if it's my alias/function"
    if [ -z ${file} ]; then
        echo "  Not my alias/function"
        echo "Checking if it's system alias/function"
        alias ${alias_to_find} > /dev/null 2>&1;
        if [ $? -ne 0 ]; then
            echo "  Not system alias/function"
            echo "Checking if it's system program"
            which ${alias_to_find}
            if [ $? -eq 1 ]; then
                echo "  Not system program"
                echo "Checking type of the command"
                type -a ${alias_to_find}
            fi
        fi
    else 
        echo "Found ${alias_to_find} in '${file}' (line ${line_number})."
        echo "Run \`bsf ${alias_to_find}\` to see details."
    fi
}
export -f my_alias

function ps1_short_dir() {
    export PROMPT_DIRTRIM=$1
}
export -f ps1_short_dir

function ps1_full_dir() {
    export PROMPT_DIRTRIM=0
}
export -f ps1_full_dir

function kill_by_grep() {
    local some_search="$1"
    for pid in $(ps -ef | grep ${some_search} | awk '{print $2}'); do 
        kill -9 $pid; 
    done
}
export -f kill_by_grep

function sudo_kill_by_grep() {
    local some_search="$1"
    for pid in $(sudo ps -ef | grep ${some_search} | awk '{print $2}'); do 
        sudo kill -9 $pid; 
    done
}
export -f sudo_kill_by_grep


function zip_dir() {
    local dir_to_zip=$1
    local my_dir=$(pwd)
    cd ${dir_to_zip} && zip -r ../${dir_to_zip}.zip .
    cd ${my_dir}
}
export -f zip_dir

# Print the version of the software/tool/application given
# Example:
# ```sh
# version tmux
# ```
function version() {
    case $1 in
        tmux)
            tmux -V
            ;;
        exiftool)
            exiftool -ver
            ;;
    esac
}
export -f version
