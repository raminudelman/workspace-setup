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

# Source the config parser
source "${SCRIPT_DIR}/lib/config-parser.sh"

# Default config file
CONFIG_FILE="${SCRIPT_DIR}/config.toml"

usage() {
    echo "Usage: $0 [options]"
    echo "  -c, --config        Specify the config file (default: config.toml)"
    echo "  --debug             Enable debug mode"
    echo "  --dry-run           Perform a dry run without making changes"
    echo "  -h, --help          Display this help message"
    echo ""
    if [ -f "$CONFIG_FILE" ]; then
        local config_profile=$(get_profile_name "$CONFIG_FILE")
        local config_env=$(get_environment_name "$CONFIG_FILE")
        echo "Current config: $CONFIG_FILE"
        echo "  Profile: ${config_profile}"
        echo "  Environment: ${config_env}"
    fi
}

function parse_args() {
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
        -c | --config)
            CONFIG_FILE="$2"
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

    # Validate config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Error: Config file not found: $CONFIG_FILE" >&2
        exit 1
    fi

    # Read profile and environment from config file
    local profile=$(get_profile_name "$CONFIG_FILE")
    local env=$(get_environment_name "$CONFIG_FILE")
    
    # Default to "default" if not specified in config
    profile="${profile:-default}"
    env="${env:-default}"

    echo "🚀 Starting workspace installation"
    echo "   Config: ${CONFIG_FILE}"
    echo "   Profile: ${profile}"
    echo "   Environment: ${env}"
    echo ""

    # Read the tools directory and run the installer of each tool
    for tool_dir in ${SCRIPT_DIR}/tools/*/; do
        tool_name="$(basename "$tool_dir")"
        echo "================================================================"
        
        # Check if tool is enabled in config
        if ! check_tool_enabled "$CONFIG_FILE" "$tool_name"; then
            echo "⏭️  Skipping tool: $tool_name (disabled in config)"
            continue
        fi
        
        if [ -f "$tool_dir/$tool_name-install.sh" ]; then
            echo "🚀 Installing tool: $tool_name"
            $tool_dir/$tool_name-install.sh ${profile} ${env}
        else
            echo "No installer found for tool: $tool_name (skipping)"
        fi
        echo "================================================================"
    done

    # Install scripts to workspace
    local scripts_dir="${HOME}/workspace/scripts"
    cp -r ${SCRIPT_DIR}/scripts "${scripts_dir}"
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
        
        for tool_dir in ${SCRIPT_DIR}/tools/*/; do
            tool_name="$(basename "$tool_dir")"
            loader_file="$HOME/.config/$tool_name/$tool_name-loader.sh"
            if [ -f "$tool_dir/$tool_name-loader.sh" ] && [ -f "$loader_file" ]; then
                echo "source \"$loader_file\""
            fi
        done
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