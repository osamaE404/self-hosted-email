#!/usr/bin/env bash
# Thin wrapper around docker-mailserver's built-in `setup` command, run
# from wherever docker-compose.yml lives. See README.md for the full
# first-run sequence.
set -euo pipefail
cd "$(dirname "$0")/.."

cmd="${1:-}"

case "$cmd" in
  dkim)
    docker compose exec mailserver setup config dkim
    echo
    echo "DKIM key generated. Its DNS TXT value is in:"
    echo "  docker-data/dms/config/rspamd/dkim/*.txt"
    ;;
  add-account)
    addr="${2:?usage: setup.sh add-account user@yourdomain}"
    docker compose exec -it mailserver setup email add "$addr"
    ;;
  list-accounts)
    docker compose exec mailserver setup email list
    ;;
  *)
    echo "usage: $0 {dkim|add-account <user@domain>|list-accounts}" >&2
    exit 1
    ;;
esac
