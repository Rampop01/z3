#!/usr/bin/env bash
# regtest-rpc.sh: developer helper script to query Zebra regtest JSON-RPC directly.
#
# Usage:
#   ./scripts/regtest-rpc.sh <method> [param1] [param2] ...
# Examples:
#   ./scripts/regtest-rpc.sh getblockchaininfo
#   ./scripts/regtest-rpc.sh getbestblockhash
#   ./scripts/regtest-rpc.sh getblock <blockhash> 1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env.regtest"

if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$ENV_FILE"
    set +a
fi

RPC_PORT="${Z3_ZEBRA_HOST_RPC_PORT:-29232}"
RPC_URL="http://127.0.0.1:${RPC_PORT}"

METHOD="${1:-getblockchaininfo}"
shift || true

# Parse arguments into JSON types (int, bool, or string)
PARAMS=$(python3 -c '
import sys, json
parsed = []
for arg in sys.argv[1:]:
    try:
        parsed.append(json.loads(arg))
    except Exception:
        parsed.append(arg)
print(json.dumps(parsed))
' "$@")

PAYLOAD=$(cat <<JSON
{"jsonrpc": "2.0", "id": "z3-cli", "method": "${METHOD}", "params": ${PARAMS}}
JSON
)

echo "==> Sending RPC '${METHOD}' to ${RPC_URL}..." >&2

RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "$RPC_URL")

if command -v jq >/dev/null 2>&1; then
    echo "$RESPONSE" | jq .
else
    echo "$RESPONSE" | python3 -m json.tool
fi
