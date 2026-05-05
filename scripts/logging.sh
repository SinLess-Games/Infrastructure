#!/usr/bin/env bash
# =============================================================================
# Bash Logging Helpers
# -----------------------------------------------------------------------------
# Purpose:
#   Shared logging functions for repository shell scripts.
#
# Usage:
#   source scripts/logging.sh
#
# Functions:
#   log_info "message"
#   log_success "message"
#   log_warn "message"
#   log_error "message"
#   log_fatal "message"
#   log_debug "message"
#
# Environment:
#   DEBUG=1              Enable debug logs
#   LOG_TIMESTAMPS=1     Add timestamps
#   NO_COLOR=1           Disable colors
#   FORCE_COLOR=1        Force colors even when output is not a TTY
# =============================================================================

# Avoid re-loading when sourced multiple times.
if [[ "${SINLESS_LOGGING_SH_LOADED:-0}" == "1" ]]; then
  return 0 2>/dev/null || exit 0
fi
SINLESS_LOGGING_SH_LOADED=1

# -----------------------------------------------------------------------------
# Color support
# -----------------------------------------------------------------------------

_log_supports_color() {
  [[ -z "${NO_COLOR:-}" ]] && { [[ -t 1 ]] || [[ "${FORCE_COLOR:-0}" == "1" ]]; }
}

if _log_supports_color; then
  LOG_RESET=$'\033[0m'
  LOG_BOLD=$'\033[1m'

  LOG_BLUE=$'\033[34m'
  LOG_GREEN=$'\033[32m'
  LOG_YELLOW=$'\033[33m'
  LOG_RED=$'\033[31m'
  LOG_BRIGHT_RED=$'\033[91m'
  LOG_DIM=$'\033[2m'
else
  LOG_RESET=""
  LOG_BOLD=""

  LOG_BLUE=""
  LOG_GREEN=""
  LOG_YELLOW=""
  LOG_RED=""
  LOG_BRIGHT_RED=""
  LOG_DIM=""
fi

# -----------------------------------------------------------------------------
# Internal helpers
# -----------------------------------------------------------------------------

_log_timestamp() {
  if [[ "${LOG_TIMESTAMPS:-0}" == "1" ]]; then
    date +"%Y-%m-%d %H:%M:%S"
  fi
}

_log_line() {
  local level="$1"
  local color="$2"
  local stream="${3:-stdout}"
  shift 3

  local message="$*"
  local timestamp=""
  local prefix=""

  timestamp="$(_log_timestamp)"

  if [[ -n "$timestamp" ]]; then
    prefix="${LOG_DIM}${timestamp}${LOG_RESET} "
  fi

  if [[ "$stream" == "stderr" ]]; then
    printf "%b%b[%s]%b | %s\n" \
      "$prefix" \
      "$color" \
      "$level" \
      "$LOG_RESET" \
      "$message" >&2
  else
    printf "%b%b[%s]%b | %s\n" \
      "$prefix" \
      "$color" \
      "$level" \
      "$LOG_RESET" \
      "$message"
  fi
}

# -----------------------------------------------------------------------------
# Public logging functions
# -----------------------------------------------------------------------------

log_info() {
  _log_line "INFO" "$LOG_BLUE" "stdout" "$@"
}

log_success() {
  _log_line "OK" "$LOG_GREEN" "stdout" "$@"
}

log_warn() {
  _log_line "WARN" "$LOG_YELLOW" "stderr" "$@"
}

log_error() {
  _log_line "ERROR" "$LOG_RED" "stderr" "$@"
}

log_fatal() {
  _log_line "FATAL" "${LOG_BOLD}${LOG_BRIGHT_RED}" "stderr" "$@"
  exit 1
}

log_debug() {
  if [[ "${DEBUG:-0}" == "1" || "${DEBUG:-false}" == "true" ]]; then
    _log_line "DEBUG" "$LOG_BLUE" "stderr" "$@"
  fi
}

# -----------------------------------------------------------------------------
# Optional command helpers
# -----------------------------------------------------------------------------

log_section() {
  local title="$*"
  printf "\n%b==> %s%b\n" "$LOG_BOLD" "$title" "$LOG_RESET"
}

log_cmd() {
  log_debug "+ $*"
  "$@"
}

log_require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    log_fatal "Required command not found: $command_name"
  fi
}