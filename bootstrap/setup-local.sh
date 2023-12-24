#!/usr/bin/env bash

set -euo pipefail

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
    kind create cluster --name "$1" --config ./config/kind-config.yaml
}

kustomize_apply() {
    kubectl apply -k "$1"
}

# Call the function to check for required commands
check_required_commands

# Create the cluster
create_cluster "local-cluster"

# Apply the bootstrap Kustomize manifests
kustomize_apply "../applications/argocd" || true
kustomize_apply "../applications/metallb" || true
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/controller -n metallb-system
# We must apply the manifests again to workaround a race condition with the CRDs
kustomize_apply "../applications/metallb"
# Register the ArgoCD and MetalLB applications with ArgoCD
kustomize_apply "../applications/_apps"

# Get the ArgoCD information
ARGOCD_SERVER_IP=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
ARGOCD_SERVER_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Output the ArgoCD server URL and password
echo "..."
echo "ArgoCD:"
echo -e "  - URL: https://${ARGOCD_SERVER_IP}"
echo -e "  - Username: admin"
echo -e "  - Password: ${ARGOCD_SERVER_PASSWORD}"
