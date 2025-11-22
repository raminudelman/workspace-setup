#!/usr/bin/env bash

############################################
###                 PATH                 ###
############################################

PATH="${HOME}/.local/bin:${PATH}"

export PATH

function path_print() {
    echo "$PATH" | tr ':' '\n'
}

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
    # TODO: Here we can call path_add_to_start_force()
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