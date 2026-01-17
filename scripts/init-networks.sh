#!/bin/bash
# Create external networks before starting any compose files
set -e

echo "Creating Docker networks..."

docker network create proxy 2>/dev/null && echo "Created 'proxy' network" || echo "Network 'proxy' already exists"
docker network create socket_proxy_network 2>/dev/null && echo "Created 'socket_proxy_network' network" || echo "Network 'socket_proxy_network' already exists"

echo ""
echo "Networks ready:"
docker network ls --filter name=proxy --filter name=socket_proxy_network
