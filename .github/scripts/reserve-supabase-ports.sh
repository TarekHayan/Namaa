#!/usr/bin/env bash
set -euo pipefail

# Docker publishes these fixed ports. Keep outgoing downloads from randomly
# claiming them from Linux's ephemeral port range before Supabase starts.
# Preserve ports reserved by the runner image or other setup steps.
existing="$(sysctl -n net.ipv4.ip_local_reserved_ports)"
reserved="${existing:+$existing,}54320-54329"
sudo sysctl -w "net.ipv4.ip_local_reserved_ports=$reserved"
