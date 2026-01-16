#!/bin/sh
set -eu

DATA_DIR="${DAT_DIR:-/data}"

P2P_BIND_IP="${P2P_BIND_IP:-0.0.0.0}"
P2P_PORT="${P2P_PORT:-18080}"

RPC_BIND_IP="${RPC_BIND_IP:-127.0.0.1}"
RPC_PORT="${RPC_PORT:-18081}"

RESTRICTED_RPC_BIND_IP="${RESTRICTED_RPC_BIND_IP:-0.0.0.0}"
RESTRICTED_RPC_PORT="${RESTRICTED_RPC_PORT:-18089}"

PUBLIC_NODE="${PUBLIC_NODE:-1}"
PRUNE="${PRUNE:-0}"
LOG_LEVEL="${LOG_LEVEL:-0}"

ARGS="--data-dir=${DATA_DIR} \
    --p2p-bind-ip=${P2P_BIND_IP} --p2p-bind-port=${P2P_PORT} \
    --rpc-bind-ip=${RPC_BIND_IP} --rpc-bind-port=${RPC_PORT} \
    --rpc-restricted-bind-ip=${RESTRICTED_RPC_BIND_IP} --rpc-restricted-bind-port=${RESTRICTED_RPC_PORT} \
    --confirm-external-bind \
    --non-interactive \
    --log-level=${LOG_LEVEL}"

if [ "$PUBLIC_NODE" = "1" ]; then
    ARGS="$ARGS --public-node"
fi

if [ "$PRUNE" = "1" ]; then
    ARGS="$ARGS --prune-blockchain"
fi

exec /usr/local/bin/monerod $ARGS ${MONEROD_EXTRA_ARGS:-}
