#!/usr/bin/env bash

# This file should be loaded/sourced during load of shell (e.g., .bashrc)

export PATH="${HOME}/workspace/software/fzf/fzf/bin:${PATH}"

source "${HOME}/workspace/software/fzf/fzf/shell/key-bindings.bash"
source "${HOME}/workspace/software/fzf/fzf/shell/completion.bash"

source "${HOME}/.config/fzf/fzf.bash"