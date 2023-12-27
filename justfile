start-cluster:
    @echo "Starting cluster..."
    ./scripts/setup-local.sh

stop-cluster:
    @echo "Stopping cluster..."
    ./scripts/teardown-local.sh