#!/usr/bin/env bash

set -euo pipefail

# Function to check if a command or program exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check for required commands
check_required_commands() {
    # Define required commands
    local required_commands=("kind")

    # Array to store missing commands
    local missing_commands=()

    # Check if the required commands are available
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done

    # Output the list of missing commands and exit if any are missing
    if [ "${#missing_commands[@]}" -gt 0 ]; then
        echo "The following tools must be installed:"
        printf -- '- %s\n' "${missing_commands[@]}"
        exit 1
    fi

    echo "All required tools are installed."
}

# Function to delete the cluster.  The name of the cluster is passed as an argument
delete_cluster() {
    # Delete the cluster
    kind delete cluster --name "$1"
}

# Call the function to check for required commands
check_required_commands

# Delete the cluster
delete_cluster "local-cluster"
