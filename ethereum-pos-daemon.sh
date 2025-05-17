#!/bin/bash

set -eu
set -o pipefail

# Display help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Sets up Ethereum proof-of-stake daemon services"
    echo ""
    echo "Options:"
    echo "  -b, --binary-dir DIR   Specify the directory containing the binaries (default: ./dependencies)"
    echo "  -h, --help             Display this help message and exit"
    echo ""
    exit 0
}

# Parse command line arguments
BINARY_DIR=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--binary-dir)
            BINARY_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root to create systemd services"
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq first."
    exit 1
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Please install curl first."
    exit 1
fi

CHAIN_ID=38888

# Get the absolute path for the current directory
INSTALL_DIR=$(pwd)

# NETWORK_DIR is where all files for the network will be stored
NETWORK_DIR=$INSTALL_DIR/network

# ===============================================
# BINARY CONFIGURATION - Edit these paths as needed
# ===============================================
# Set default binary directory if not provided via command line
if [ -z "$BINARY_DIR" ]; then
    BINARY_DIR=$INSTALL_DIR/dependencies
fi

echo "Using binary directory: $BINARY_DIR"

# Execution client binaries
GETH_BINARY=$BINARY_DIR/dependencies/go-ethereum/build/bin/geth

# Consensus client binaries
PRYSM_CTL_BINARY=$BINARY_DIR/dependencies/prysm/bazel-bin/cmd/prysmctl/prysmctl_/prysmctl
PRYSM_BEACON_BINARY=$BINARY_DIR/dependencies/prysm/bazel-bin/cmd/beacon-chain/beacon-chain_/beacon-chain
PRYSM_VALIDATOR_BINARY=$BINARY_DIR/dependencies/prysm/bazel-bin/cmd/validator/validator_/validator
# ===============================================

# Check if binaries exist
if [ ! -f "$GETH_BINARY" ]; then
    echo "Error: Geth binary not found at $GETH_BINARY"
    exit 1
fi

if [ ! -f "$PRYSM_CTL_BINARY" ]; then
    echo "Error: Prysm CTL binary not found at $PRYSM_CTL_BINARY"
    exit 1
fi

if [ ! -f "$PRYSM_BEACON_BINARY" ]; then
    echo "Error: Prysm Beacon Chain binary not found at $PRYSM_BEACON_BINARY"
    exit 1
fi

if [ ! -f "$PRYSM_VALIDATOR_BINARY" ]; then
    echo "Error: Prysm Validator binary not found at $PRYSM_VALIDATOR_BINARY"
    exit 1
fi

# Set production IP address - bind to all interfaces
BIND_IP="0.0.0.0"

# Port information
GETH_HTTP_PORT=8545
GETH_WS_PORT=8546
GETH_AUTH_RPC_PORT=8551
GETH_METRICS_PORT=6060
GETH_NETWORK_PORT=30303

PRYSM_BEACON_RPC_PORT=4000
PRYSM_BEACON_GRPC_GATEWAY_PORT=3500
PRYSM_BEACON_P2P_TCP_PORT=13000
PRYSM_BEACON_P2P_UDP_PORT=12000
PRYSM_BEACON_MONITORING_PORT=8080

PRYSM_VALIDATOR_RPC_PORT=7000
PRYSM_VALIDATOR_GRPC_GATEWAY_PORT=7500
PRYSM_VALIDATOR_MONITORING_PORT=8081

# Stop and disable existing services
echo "Stopping existing services if running..."
systemctl stop validator.service 2>/dev/null || true
systemctl stop beacon-chain.service 2>/dev/null || true
systemctl stop geth.service 2>/dev/null || true
echo "Waiting for services to fully stop..."
sleep 5

# Create network directory structure
echo "Creating network directory structure..."
mkdir -p $NETWORK_DIR
mkdir -p $NETWORK_DIR/execution
mkdir -p $NETWORK_DIR/consensus
mkdir -p $NETWORK_DIR/consensus/beacondata
mkdir -p $NETWORK_DIR/consensus/validatordata
mkdir -p $NETWORK_DIR/logs

# Generate genesis files
echo "Generating genesis files..."
$PRYSM_CTL_BINARY testnet generate-genesis \
  --fork=deneb \
  --num-validators=1 \
  --chain-config-file=$BINARY_DIR/config.yml \
  --geth-genesis-json-in=$BINARY_DIR/genesis.json \
  --output-ssz=$NETWORK_DIR/genesis.ssz \
  --geth-genesis-json-out=$NETWORK_DIR/genesis.json

# Copy config files
cp $BINARY_DIR/config.yml $NETWORK_DIR/consensus/config.yml
cp $NETWORK_DIR/genesis.json $NETWORK_DIR/execution/genesis.json

# Create empty password file for geth
geth_pw_file="$NETWORK_DIR/geth_password.txt"
echo "" > "$geth_pw_file"

# Create account for execution client
echo "Creating execution client account..."
$GETH_BINARY account new --datadir "$NETWORK_DIR/execution" --password "$geth_pw_file"

$GETH_BINARY init \
  --datadir=$NETWORK_DIR/execution \
  --state.scheme=hash \
  $NETWORK_DIR/execution/genesis.json

# Create JWT secret for client communication
echo "Creating JWT secret..."
openssl rand -hex 32 > $NETWORK_DIR/execution/jwtsecret

# Create systemd service files
echo "Creating systemd service files..."

# Create geth systemd service
cat > /etc/systemd/system/geth.service << EOF
[Unit]
Description=Ethereum execution client (geth)
After=network.target
Wants=network.target

[Service]
User=$(whoami)
ExecStart=$GETH_BINARY \\
  --networkid=${CHAIN_ID:-32382} \\
  --http \\
  -http.api=eth,net,web3,debug,admin,txpool,miner \\
  --http.addr=$BIND_IP \\
  --http.corsdomain="*" \\
  --http.vhosts="localhost,testnet.aiigo.org" \\
  --http.port=$GETH_HTTP_PORT \\
  --port=$GETH_NETWORK_PORT \\
  --metrics.port=$GETH_METRICS_PORT \\
  --ws \\
  --ws.api=eth,net,web3,debug,admin,txpool,miner \\
  --ws.addr=$BIND_IP \\
  --ws.origins="*" \\
  --ws.port=$GETH_WS_PORT \\
  --authrpc.vhosts="*" \\
  --authrpc.addr=$BIND_IP \\
  --authrpc.jwtsecret=$NETWORK_DIR/execution/jwtsecret \\
  --authrpc.port=$GETH_AUTH_RPC_PORT \\
  --datadir=$NETWORK_DIR/execution \\
  --password=$geth_pw_file \\
  --maxpendpeers=50 \\
  --verbosity=1 \\
  --gcmode=archive \\
  --syncmode=full
Restart=on-failure
RestartSec=5
WorkingDirectory=$INSTALL_DIR
StandardOutput=append:$NETWORK_DIR/logs/geth.log
StandardError=append:$NETWORK_DIR/logs/geth.err

[Install]
WantedBy=default.target
EOF

# Create beacon chain systemd service
cat > /etc/systemd/system/beacon-chain.service << EOF
[Unit]
Description=Ethereum consensus client (prysm beacon chain)
After=network.target geth.service
Wants=network.target geth.service

[Service]
User=$(whoami)
ExecStart=$PRYSM_BEACON_BINARY \\
  --datadir=$NETWORK_DIR/consensus/beacondata \\
  --min-sync-peers=0 \\
  --genesis-state=$NETWORK_DIR/genesis.ssz \\
  --interop-eth1data-votes \\
  --chain-config-file=$NETWORK_DIR/consensus/config.yml \\
  --contract-deployment-block=0 \\
  --chain-id=${CHAIN_ID:-32382} \\
  --rpc-host=$BIND_IP \\
  --rpc-port=$PRYSM_BEACON_RPC_PORT \\
  --grpc-gateway-host=$BIND_IP \\
  --grpc-gateway-port=$PRYSM_BEACON_GRPC_GATEWAY_PORT \\
  --execution-endpoint=http://$BIND_IP:$GETH_AUTH_RPC_PORT \\
  --accept-terms-of-use \\
  --jwt-secret=$NETWORK_DIR/execution/jwtsecret \\
  --suggested-fee-recipient=0xbc76587a650ed157F8142d73b56781fB245270EC \\
  --minimum-peers-per-subnet=0 \\
  --p2p-tcp-port=$PRYSM_BEACON_P2P_TCP_PORT \\
  --p2p-udp-port=$PRYSM_BEACON_P2P_UDP_PORT \\
  --monitoring-port=$PRYSM_BEACON_MONITORING_PORT \\
  --verbosity=warning \\
  --slasher \\
  --enable-debug-rpc-endpoints
Restart=on-failure
RestartSec=5
WorkingDirectory=$INSTALL_DIR
StandardOutput=append:$NETWORK_DIR/logs/beacon.log
StandardError=append:$NETWORK_DIR/logs/beacon.err

[Install]
WantedBy=default.target
EOF

# Create validator systemd service
cat > /etc/systemd/system/validator.service << EOF
[Unit]
Description=Ethereum validator client (prysm)
After=network.target beacon-chain.service
Wants=network.target beacon-chain.service

[Service]
User=$(whoami)
ExecStart=$PRYSM_VALIDATOR_BINARY \\
  --beacon-rpc-provider=$BIND_IP:$PRYSM_BEACON_RPC_PORT \\
  --datadir=$NETWORK_DIR/consensus/validatordata \\
  --accept-terms-of-use \\
  --interop-num-validators=1 \\
  --interop-start-index=0 \\
  --rpc-port=$PRYSM_VALIDATOR_RPC_PORT \\
  --grpc-gateway-port=$PRYSM_VALIDATOR_GRPC_GATEWAY_PORT \\
  --monitoring-port=$PRYSM_VALIDATOR_MONITORING_PORT \\
  --graffiti="ethereum-pos-validator" \\
  --verbosity=warning \\
  --chain-config-file=$NETWORK_DIR/consensus/config.yml
Restart=on-failure
RestartSec=5
WorkingDirectory=$INSTALL_DIR
StandardOutput=append:$NETWORK_DIR/logs/validator.log
StandardError=append:$NETWORK_DIR/logs/validator.err

[Install]
WantedBy=default.target
EOF

# Reload systemd
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable and start services
echo "Enabling and starting services..."
systemctl enable geth.service
systemctl enable beacon-chain.service
systemctl enable validator.service

echo "Starting geth service with archive mode..."
systemctl start geth.service
echo "Started geth service. Waiting 10 seconds before starting beacon chain..."
sleep 10

systemctl start beacon-chain.service
echo "Started beacon chain service. Waiting 10 seconds before starting validator..."
sleep 10

systemctl start validator.service
echo "Started validator service."

echo "Services are now running. To check status:"
echo "  systemctl status geth.service"
echo "  systemctl status beacon-chain.service"
echo "  systemctl status validator.service"
echo ""
echo "To view logs:"
echo "  journalctl -fu geth.service"
echo "  journalctl -fu beacon-chain.service" 
echo "  journalctl -fu validator.service"
echo ""
echo "Log files are also available at:"
echo "  $NETWORK_DIR/logs/" 