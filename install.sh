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

# Environment override (empty means use default from config)
ENV_OVERRIDE=""

usage() {
    echo "Usage: $0 [options]"
    echo "  -c, --config        Specify the config file (default: config.toml)"
    echo "  -e, --env           Specify the environment to use"
    echo "  --debug             Enable debug mode"
    echo "  --dry-run           Perform a dry run without making changes"
    echo "  -h, --help          Display this help message"
    echo ""
    if [ -f "$CONFIG_FILE" ]; then
        local config_profile=$(get_profile_name "$CONFIG_FILE")
        local default_env=$(get_default_environment "$CONFIG_FILE")
        local available_envs=$(get_available_environments "$CONFIG_FILE")
        echo "Current config: $CONFIG_FILE"
        echo "  Profile: ${config_profile}"
        echo "  Default environment: ${default_env}"
        echo ""
        echo "Available environments:"
        for env in $available_envs; do
            local desc=$(get_environment_description "$CONFIG_FILE" "$env")
            if [ "$env" == "$default_env" ]; then
                echo "  - $env (default): $desc"
            else
                echo "  - $env: $desc"
            fi
        done
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
        -e | --env)
            ENV_OVERRIDE="$2"
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
    local env=$(get_default_environment "$CONFIG_FILE")
    
    # Use override if provided
    if [ -n "$ENV_OVERRIDE" ]; then
        env="$ENV_OVERRIDE"
    fi
    
    # Default to "default" if not specified in config
    profile="${profile:-default}"
    env="${env:-default}"
    
    # Validate that the environment is available
    if ! is_valid_environment "$CONFIG_FILE" "$env"; then
        echo "❌ Error: Invalid environment '$env'" >&2
        echo "Available environments: $(get_available_environments "$CONFIG_FILE")" >&2
        exit 1
    fi

    echo "🚀 Starting workspace installation"
    echo "   Config: ${CONFIG_FILE}"
    echo "   Profile: ${profile}"
    echo "   Environment: ${env}"
    echo ""

    # Read the tools directory and run the installer of each tool
    for tool_dir in "${SCRIPT_DIR}"/tools/*/; do
        tool_name="$(basename "$tool_dir")"
        echo "================================================================"
        # Check if tool is enabled in config for this environment
        if ! check_tool_enabled "$CONFIG_FILE" "$tool_name" "$env"; then
            echo "⏭️  Skipping tool: $tool_name (disabled or not available in '$env' environment)"
            continue
        fi

        installer="$tool_dir/${tool_name}-install.sh"
        if [ -f "$installer" ]; then
            echo "🚀 Installing tool: $tool_name"
            # Run installer guarded so a failing installer doesn't abort the entire run
            if ! bash "$installer" "$profile" "$env"; then
                echo "❌ Error: Installer for $tool_name failed (see above). Continuing with next tool."
                continue
            fi
        else
            echo "❌ Error: No installer found for tool: $tool_name (skipping)"
            exit 1
        fi
        echo "================================================================"
    done

    # Install scripts to workspace
    local scripts_dir="${HOME}/workspace/scripts"
    mkdir -p "${scripts_dir}"
    # Copy everything (including hidden files) from scripts/ into target
    cp -r "${SCRIPT_DIR}/scripts/." "${scripts_dir}/"
    echo "📁 Copied scripts to workspace directory: ${scripts_dir}"
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