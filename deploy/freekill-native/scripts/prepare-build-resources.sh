#!/usr/bin/env bash
set -Eeuo pipefail

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

if [[ "$(id -u)" -ne 0 ]]; then
  die "Run as root, for example: sudo $0"
fi

command -v awk >/dev/null 2>&1 || die 'awk is required'
command -v swapon >/dev/null 2>&1 || die 'swapon is required'
command -v mkswap >/dev/null 2>&1 || die 'mkswap is required'
command -v fallocate >/dev/null 2>&1 || die 'fallocate is required'

mem_kib="$(awk '/^MemTotal:/ { print $2; exit }' /proc/meminfo)"
[[ "$mem_kib" =~ ^[0-9]+$ ]] || die 'Could not read MemTotal from /proc/meminfo'

# A 1 GiB Oracle VM can compile the pinned C++ source only with serial build
# jobs and a small persistent swap area. Do not alter larger hosts that already
# have enough memory, and do not replace an existing swap configuration.
if (( mem_kib > 2097152 )); then
  printf 'Build resources: %s KiB RAM; no small-host swap change required.\n' "$mem_kib"
  exit 0
fi

swap_total_kib="$(awk '/^SwapTotal:/ { print $2; exit }' /proc/meminfo)"
[[ "$swap_total_kib" =~ ^[0-9]+$ ]] || die 'Could not read SwapTotal from /proc/meminfo'
if (( swap_total_kib > 0 )); then
  printf 'Build resources: existing swap detected (%s KiB).\n' "$swap_total_kib"
  exit 0
fi

swap_file="${FREEKILL_SWAP_FILE:-/swapfile}"
swap_size="${FREEKILL_SWAP_SIZE:-2G}"
if [[ -e "$swap_file" ]]; then
  die "Swap target already exists but is not active; refusing to overwrite: $swap_file"
fi

swap_dir="$(dirname -- "$swap_file")"
install -d -m 0755 "$swap_dir"
fallocate -l "$swap_size" "$swap_file" || die "Could not allocate swap file: $swap_file"
chmod 0600 "$swap_file"
mkswap "$swap_file" >/dev/null
swapon "$swap_file"

if ! awk -v target="$swap_file" '$1 == target && $3 == "swap" { found = 1 } END { exit found ? 0 : 1 }' /etc/fstab; then
  printf '%s none swap sw 0 0\n' "$swap_file" >> /etc/fstab
fi

sysctl -w vm.swappiness=10 >/dev/null
sysctl_file="/etc/sysctl.d/99-freekill-build.conf"
if [[ ! -f "$sysctl_file" ]] || ! grep -Fxq 'vm.swappiness=10' "$sysctl_file"; then
  printf 'vm.swappiness=10\n' > "$sysctl_file"
fi

printf 'Build resources: enabled %s swap and vm.swappiness=10.\n' "$swap_file"
