#!/usr/bin/env bash

# Print usage information
usage() {
    echo "Usage: $0 [options]"
    echo "  -c, --clean-test    Clean previous installation before running the test"
    echo "  --debug             Enable debug mode"
    echo "  --dry-run           Perform a dry run without making changes"
    echo "  -h, --help          Display this help message"
    echo ""
}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

INSTALL_DIR="${SCRIPT_DIR}/install/home"

# If set to true, cleans previous installation before running the test
CLEAN_TEST=false

function parse_args() {
    # Parse arguments
    while true; do
        case "$1" in
        -c | --clean-test)
            CLEAN_TEST=true
            shift 1
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

    echo "Starting test installation in ${INSTALL_DIR}"

    # Clean previous test installation
    if [ -d "${INSTALL_DIR}" ] && [ "$CLEAN_TEST" = true ]; then
        rm -rf "${INSTALL_DIR}"
    fi

    mkdir -p "${INSTALL_DIR}"

    # Run the installation script
    echo "Running install.sh with HOME=${INSTALL_DIR}"

    # Setting HOME so the test will not interfere with the actual user
    # configuration files.
    HOME=${INSTALL_DIR} ${SCRIPT_DIR}/install.sh --env default --profile default

    echo "Continue the test to source .bashrc"

    if [ ! -f "${INSTALL_DIR}/.bashrc" ]; then
        echo "Error: ${INSTALL_DIR}/.bashrc not found!"
        exit 1
    fi

    # Running .bashrc in an interactive shell. Otherwise, bashrc is exiting early.
    bash -i -c "HOME=${INSTALL_DIR} source ${INSTALL_DIR}/.bashrc &&\
       which fzf &&\
       which bat &&\
       which delta &&\
       which lazygit &&\
       which tmux &&\
       which git"

    echo "✅ Test installation completed successfully in ${INSTALL_DIR}"
}

# https://unix.stackexchange.com/questions/449498/call-function-declared-below
main "$@"; exit


