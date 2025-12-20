#!/usr/bin/env bash
# scripts/logging.sh
# Simple colored logging helpers for bash scripts

# Reset
LOG_RESET="\033[0m"

# Colors
LOG_BLUE="\033[34m"
LOG_YELLOW="\033[33m"
LOG_RED="\033[31m"
LOG_BRIGHT_RED="\033[91m"
LOG_BOLD="\033[1m"

_log() {
  local level="$1"
  local color="$2"
  shift 2

  printf "%b[%s] | %b%s%b\n" \
    "${color}" \
    "${level}" \
    "${LOG_RESET}" \
    "$*" \
    "${LOG_RESET}"
}

log_info() {
  _log "INFO" "${LOG_BLUE}" "$@"
}

log_warn() {
  _log "WARN" "${LOG_YELLOW}" "$@"
}

log_error() {
  _log "ERROR" "${LOG_RED}" "$@"
}

log_fatal() {
  printf "%b[%s] | %b%s%b\n" \
    "${LOG_BOLD}${LOG_BRIGHT_RED}" \
    "FATAL" \
    "${LOG_RESET}" \
    "$*" \
    "${LOG_RESET}"
  exit 1
}

log_debug() {
  if [[ "${DEBUG:-0}" == "1" ]]; then
    _log "DEBUG" "${LOG_BLUE}" "$@"
  fi
}
