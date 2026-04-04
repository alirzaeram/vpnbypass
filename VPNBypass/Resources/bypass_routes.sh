#!/bin/bash
# Bundled helper for privileged route changes. Called with explicit arguments from the app.
# Actions:
#   gateway  — print IPv4 default gateway (no admin typically required when invoked directly)
#   apply    — add host routes for IPs via gateway (requires root)
#   remove   — delete host routes for IPs (requires root)
set -euo pipefail

ACTION="${1:?missing action}"
shift || true

case "$ACTION" in
  gateway)
    # Prefer structured parsing of `route -n get default` on macOS.
    /sbin/route -n get default 2>/dev/null | awk '/gateway:/{print $2; exit}'
    ;;
  apply)
    GATEWAY="${1:?missing gateway}"
    shift
    if [[ $# -eq 0 ]]; then
      echo "apply: no IPs provided" >&2
      exit 2
    fi
    for ip in "$@"; do
      if [[ ! "$ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
        echo "apply: skipping non-IPv4: $ip" >&2
        continue
      fi
      # Clear any stale host route, then pin this host via the local gateway.
      /sbin/route -n delete -host "$ip" 2>/dev/null || true
      /sbin/route -n add -host "$ip" "$GATEWAY"
    done
    ;;
  remove)
    if [[ $# -eq 0 ]]; then
      echo "remove: no IPs provided" >&2
      exit 2
    fi
    for ip in "$@"; do
      if [[ ! "$ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
        echo "remove: skipping non-IPv4: $ip" >&2
        continue
      fi
      /sbin/route -n delete -host "$ip" 2>/dev/null || true
    done
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    exit 2
    ;;
esac
