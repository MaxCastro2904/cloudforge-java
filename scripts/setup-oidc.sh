#!/usr/bin/env bash
# Initial IAM and backend setup is managed by the bootstrap Terraform stack.
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec bash "$here/bootstrap-infra.sh" "$@"
