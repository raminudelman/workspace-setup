#!/usr/bin/env bash

# Make sure we exit on errors
set -euo pipefail

# Get the directory of the current script regardless of where it's called from
# and no matter if this script was "sourced" or was executed.
# First backup the current SCRIPT_DIR in case some other script called this
# script and uses the same variable name SCRIPT_DIR. The backup will be
# restored in the end of this script. Implemented using a stack.
if [ -n "${SCRIPT_DIR+x}" ]; then
    SCRIPT_DIR_STACK+=("${SCRIPT_DIR}")
fi
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Default environment is default
DEFAULT_ENV="default"
ENV="$DEFAULT_ENV"

DEFAULT_PROFILE="default"
PROFILE="$DEFAULT_PROFILE"

usage() {
    echo "Usage: $0 [options]"
    echo "  -e, --env           Specify the environment"
    echo "  -p, --profile       Specify the profile"
    echo "  --debug             Enable debug mode"
    echo "  --dry-run           Perform a dry run without making changes"
    echo "  -h, --help          Display this help message"
    echo ""
    echo "Available environments: "
    # List available environments based on existing bash-local-*.sh files
    for file in ./tools/bash/bash-local-*.sh; do
        env_name=$(basename "$file" | sed -E 's/bash-local-(.*)\.sh/\1/')
        if ([ "$env_name" == "${DEFAULT_ENV}" ]); then
            echo "  - $env_name (default)"
            continue
        fi
        echo "  - $env_name"
    done
    echo ""
    echo "Available profiles: "
    echo "  - default (default)"
}

function parse_args() {
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
        -e | --env)
            ENV="$2"
            shift 2
            continue
            ;;
        -p | --profile)
            PROFILE="$2"
            shift 2
            continue
            ;;
        --debug)
            DEBUG=true
            shift 1
            continue
            ;;
        --dry-run)
            DRY_EXECUTION=true
            shift 1
            continue
            ;;
        -h | --help)
            usage;
            exit 0
            break
            ;;
        --) # End of all options
            shift
            break
            ;;
        -*) # Unknown option
            echo "Error: Unknown option: $1" >&2
            exit 1
            ;;
        *) # No more options
            break
            ;;
        esac
    done
}

main() {
    parse_args "$@"

    # Read the tools directory and run the installer of each tool
    for tool_dir in ./tools/*/; do
        tool_name="$(basename "$tool_dir")"
        if [ -f "$tool_dir/$tool_name-install.sh" ]; then
            echo "🚀 Installing tool: $tool_name"
            $tool_dir/$tool_name-install.sh ${ENV} ${PROFILE}
        else
            echo "No installer found for tool: $tool_name (skipping)"
        fi
    done

    # Install scripts to workspace
    local scripts_dir="${HOME}/workspace/scripts"
    cp -r ./scripts "${scripts_dir}"
    echo "📁 Copied scripts to workspace directory"
    # Build the loader.sh script dynamically based on the available directories
    # in scripts/ and make sure these are added to the PATH through a loader
    # file that will be put in ${scripts_dir}/loader.sh
    {
        echo "#!/usr/bin/env bash"
        echo ""
        echo "# Auto-generated loader script for workspace scripts"
        echo "# Generated on $(date)"
        echo ""
        echo "export PATH=\"\$PATH:${scripts_dir}\""
        for subdir in ${scripts_dir}/*/; do
            echo "export PATH=\"\$PATH:${subdir}\""
        done
    } > "${scripts_dir}/loader.sh"


    # Generate the config loader script directly to the target location
    {
        echo "#!/usr/bin/env bash"
        echo ""
        echo "# Auto-generated loader script for workspace tools"
        echo "# Generated on $(date)"
        echo ""
        
        for tool_dir in ./tools/*/; do
            tool_name="$(basename "$tool_dir")"
            loader_file="$HOME/.config/$tool_name/$tool_name-loader.sh"
            if [ -f "$tool_dir/$tool_name-loader.sh" ] && [ -f "$loader_file" ]; then
                echo "source \"$loader_file\""
            fi
        done
        echo "source \"${HOME}/.config/bash/bash-local-${ENV}.sh\""
        echo "source \"${scripts_dir}/loader.sh\""
    } > "$HOME/.config/loader.sh"

    echo "Workspace installation completed."
}

main "$@"

# Restore (pop) the previous SCRIPT_DIR from the stack
if [ -n "${SCRIPT_DIR_STACK+x}" ] && [ ${#SCRIPT_DIR_STACK[@]} -gt 0 ]; then
    SCRIPT_DIR="${SCRIPT_DIR_STACK[-1]}"
    unset 'SCRIPT_DIR_STACK[-1]'
else
    unset SCRIPT_DIR
fi