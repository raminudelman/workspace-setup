# Workspace setup

A development environment configuration management system that automates the setup of a customized shell and development toolchain across multiple computing environments.

## Features

- **Environment-aware installation** - Tailored configurations for different machines (WSL, HPC clusters, GPU clusters)
- **Profile-based customization** - Different profiles for work, personal, etc.
- **Configuration-driven** - TOML-based configuration controls which tools are installed
- **Non-destructive** - All tools install to `$HOME/workspace/software/` without polluting system directories
- **Modular design** - Each tool has its own installer and configuration

## Installation

```sh
./install.sh --env <environment> --profile <profile>
```

> **Note**
>
> Check available environments and profiles by running `./install.sh --help`

### What the installation does

1. Parses `config.toml` to determine which tools to install for your environment
2. Installs tools to `$HOME/workspace/software/<tool>/`
3. Symlinks configuration files to `$HOME/.config/<tool>/`
4. Creates environment-specific configurations (e.g., `bash-local-work-wsl.sh`)
5. Copies utility scripts to `$HOME/workspace/scripts/` with auto-generated PATH loader
6. Creates master loader at `~/.config/loader.sh` that sources all tool configurations

> **Note**
>
> Profile affects which configurations are installed. Different profiles use different git user settings. See `tools/git/git-install.sh` for details.

## Tools Managed

### Shell and Terminal
- **bash** - Shell configuration with aliases, functions, custom prompts, and environment-specific settings
- **tmux** - Terminal multiplexer with TPM (Tmux Plugin Manager) support

### Git
- **git** - Comprehensive git configuration (278 lines of aliases, colors, diff settings, etc.)
- **delta** - Enhanced git diff viewer with syntax highlighting
- **lazygit** - Terminal UI for git commands

### Command-line Utilities
- **fzf** - Fuzzy finder for files and command history
- **eza** - Modern replacement for `ls` with git integration
- **bat** - Syntax-highlighted replacement for `cat`

## Configuration

The `config.toml` file controls which tools are installed for each environment:

```toml
[tools.bash]
enabled = true
environments = ["env-1", "env-2"] # Only install on `env-1` and `env-2`.

[tools.tmux]
enabled = true
environments = ["env-1"]  # Only install on `env-1`
```

You can customize which tools are installed by editing this file.

## Directory Structure

```
workspace-setup/
├── config.toml              # Main configuration file
├── install.sh               # Main installation script
├── lib/
│   └── config-parser.sh     # TOML parser library
├── tools/                   # Tool-specific installers and configs
│   ├── bash/
│   ├── git/
│   ├── fzf/
│   ├── eza/
│   ├── bat/
│   ├── delta/
│   ├── tmux/
│   └── lazygit/
└── scripts/                 # Utility scripts
    └── git/                 # Git workflow helpers
```

## Utility Scripts

The `scripts/git/` directory contains helpful scripts.

These scripts are automatically copied to `$HOME/workspace/scripts/` during installation.

## Testing

To install locally and see how the workspace will be setup, run `./test.sh` and check the newly created `./install/` directory:

```sh
./test.sh [--clean-test] [--env <env>]
```

Then `.bashrc` can be sourced in the current shell session:

```sh
HOME=$PWD/install/home source ./install/home/.bashrc
```

This creates an isolated installation for testing without affecting your actual home directory.