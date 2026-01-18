#!/usr/bin/env bash

# Configuration parser for workspace-setup
# Provides functions to read TOML config files

# Get a value from the config file
# Usage: get_config_value <config_file> <key>
# Example: get_config_value "config.toml" "profile.name"
get_config_value() {
    local config_file="$1"
    local key="$2"
    
    if [ ! -f "$config_file" ]; then
        return 1
    fi
    
    # Convert TOML path to grep pattern
    # e.g., "profile.name" -> look for name under [profile]
    local section=""
    local field=""
    
    if [[ "$key" == *.* ]]; then
        section="${key%.*}"
        field="${key##*.}"
    else
        field="$key"
    fi
    
    # Parse TOML: Find section, then find field
    local in_section=0
    local result=""
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Check if we're entering the target section
        if [[ "$line" =~ ^\[([^]]+)\] ]]; then
            local current_section="${BASH_REMATCH[1]}"
            if [ -z "$section" ] || [ "$current_section" == "$section" ]; then
                in_section=1
            else
                in_section=0
            fi
            continue
        fi
        
        # If we're in the right section (or no section specified), look for the field
        if [ $in_section -eq 1 ]; then
            if [[ "$line" =~ ^[[:space:]]*${field}[[:space:]]*=[[:space:]]*(.+)$ ]]; then
                result="${BASH_REMATCH[1]}"
                # Remove quotes and trailing comments
                result="${result#\"}"
                result="${result%\"}"
                result="${result%%#*}"
                result="${result%% }"
                echo "$result"
                return 0
            fi
        fi
    done < "$config_file"
    
    return 1
}

# Check if a tool is enabled in the config for a specific environment
# Usage: check_tool_enabled <config_file> <tool_name> [environment]
# Returns: 0 if enabled, 1 if disabled or not found
check_tool_enabled() {
    local config_file="$1"
    local tool_name="$2"
    local environment="${3:-}"
    
    if [ ! -f "$config_file" ]; then
        # If no config file, assume enabled (backward compatibility)
        return 0
    fi
    
    local enabled=$(get_config_value "$config_file" "tools.${tool_name}.enabled")
    
    if [ -z "$enabled" ]; then
        # If not specified, assume enabled
        return 0
    fi
    
    if [ "$enabled" != "true" ]; then
        return 1
    fi
    
    # Check if tool is restricted to specific environments
    if [ -n "$environment" ]; then
        local tool_envs=$(get_config_value "$config_file" "tools.${tool_name}.environments")
        if [ -n "$tool_envs" ]; then
            # Tool has environment restrictions - check if current env is in the list
            # Remove brackets and quotes, convert to space-separated
            tool_envs="${tool_envs#\[}"
            tool_envs="${tool_envs%\]}"
            tool_envs="${tool_envs//\"/}"
            tool_envs="${tool_envs//,/ }"
            
            local found=0
            for env in $tool_envs; do
                if [ "$env" == "$environment" ]; then
                    found=1
                    break
                fi
            done
            
            if [ $found -eq 0 ]; then
                return 1
            fi
        fi
    fi
    
    return 0
}

# Get profile name from config
# Usage: get_profile_name <config_file>
get_profile_name() {
    local config_file="$1"
    get_config_value "$config_file" "profile.name"
}

# Get default environment name from config
# Usage: get_default_environment <config_file>
get_default_environment() {
    local config_file="$1"
    get_config_value "$config_file" "environments.default"
}

# Get available environments from config
# Usage: get_available_environments <config_file>
# Returns: space-separated list of environment names
get_available_environments() {
    local config_file="$1"
    local available=$(get_config_value "$config_file" "environments.available")
    # Remove brackets and quotes, convert to space-separated
    available="${available#\[}"
    available="${available%\]}"
    available="${available//\"/}"
    available="${available//,/ }"
    echo "$available"
}

# Check if an environment is valid (exists in available list)
# Usage: is_valid_environment <config_file> <env_name>
# Returns: 0 if valid, 1 if not
is_valid_environment() {
    local config_file="$1"
    local env_name="$2"
    local available=$(get_available_environments "$config_file")
    
    for env in $available; do
        if [ "$env" == "$env_name" ]; then
            return 0
        fi
    done
    return 1
}

# Get environment description from config
# Usage: get_environment_description <config_file> <env_name>
get_environment_description() {
    local config_file="$1"
    local env_name="$2"
    get_config_value "$config_file" "environments.${env_name}.description"
}
