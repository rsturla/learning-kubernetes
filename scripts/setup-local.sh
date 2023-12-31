#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"

# Function to check if a command or program exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check for required commands
check_required_commands() {
    # Define required commands
    local required_commands=("kind" "kubectl")

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

# Function to create the cluster.  The name of the cluster is passed as an argument
create_cluster() {
    # Create the cluster
    kind create cluster --name "$1" --config $SCRIPT_DIR/config/kind-config.yaml
}

kustomize_apply() {
    kubectl apply -k "$1"
}

kubectl_apply() {
    kubectl apply -f "$1"
}

# Call the function to check for required commands
check_required_commands

# Create the cluster
create_cluster "local-cluster"

# Apply the bootstrap Kustomize manifests
kustomize_apply "$SCRIPT_DIR/../applications/argocd"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl_apply "$SCRIPT_DIR/../applications/apps.yml"

# Get the ArgoCD information
ARGOCD_SERVER_URL=$(kubectl -n argocd get ingress argocd-server-ingress -o jsonpath="{.spec.rules[0].host}")
ARGOCD_SERVER_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Output the ArgoCD server URL and password to the console
echo "..."
echo "ArgoCD (local-cluster):"
echo -e "  - URL: https://argocd.example.com"
echo -e "  - Username: admin"
echo -e "  - Password: ${ARGOCD_SERVER_PASSWORD}"

# Output the ArgoCD server URL and password to a file
cat <<EOF > "$SCRIPT_DIR/../.argocd"
ARGOCD_SERVER_URL=https://argocd.example.com
ARGOCD_SERVER_USERNAME=admin
ARGOCD_SERVER_PASSWORD=$ARGOCD_SERVER_PASSWORD
EOF
