start-cluster:
    @echo "Starting cluster..."
    ./scripts/setup-local.sh

stop-cluster:
    @echo "Stopping cluster..."
    ./scripts/teardown-local.sh

watch-pods:
    @echo "Watching pods..."
    kubectl get pods --all-namespaces -w

watch-svcs:
    @echo "Watching services..."
    kubectl get svc --all-namespaces -w
