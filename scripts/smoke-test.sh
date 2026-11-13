#!/usr/bin/env bash
set -euo pipefail
base="${1:?Pass the public base URL}"
for attempt in $(seq 1 30); do
  if response=$(curl --fail --silent --show-error --connect-timeout 5 --max-time 10 "$base/api/hello"); then
    if RESPONSE="$response" python3 -c 'import os,json; assert json.loads(os.environ["RESPONSE"])["message"] == "Hola Mundo"'; then
      curl --fail --silent --show-error --max-time 10 "$base/health"
      echo
      echo "Public endpoint OK: $base/api/hello"
      exit 0
    fi
  fi
  echo "Waiting for public endpoint (attempt $attempt/30)..."
  sleep 10
done
echo "Endpoint did not become healthy" >&2
exit 1
