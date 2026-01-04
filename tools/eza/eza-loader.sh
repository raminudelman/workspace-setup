#!/usr/bin/env bash

# This file should be loaded during load of shell (e.g., .bashrc)

export PATH="${HOME}/workspace/software/eza/eza/bin:${PATH}"

# eza aliases
if command -v eza >/dev/null 2>&1; then
    # Standard list (replace ls)
    alias ls='eza --icons --group-directories-first'
    
    # Long list (metadata, permissions, etc.)
    # -a : include hidden files
    # -h : human-readable sizes
    # -l : long format
    alias ll='eza -lh -a --icons --git --group-directories-first'
    
    # List all including hidden files
    alias la='eza -a --icons --group-directories-first'
    
    # Tree view
    alias tree='eza --tree --icons --git --level=2'
fi
