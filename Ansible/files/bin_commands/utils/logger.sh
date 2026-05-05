#!/usr/bin/env bash
# =============================================================================
# logger.sh
# -----------------------------------------------------------------------------
# Reusable Bash logger for SinLess Games infrastructure scripts.
#
# This file is designed to be sourced by other scripts:
#
#   # shellcheck source=/dev/null
#   source "/path/to/logger.sh"
#
# Public functions:
#   log_error   "message"  -> stderr, red
#   log_warn    "message"  -> stderr, yellow
#   log_success "message"  -> stdout, green
#   log_info    "message"  -> stdout, cyan
#   log_debug   "message"  -> stdout, dim, only when LOG_LEVEL=DEBUG/TRACE
#   log_trace   "message"  -> stdout, dim, only when LOG_LEVEL=TRACE
#   log_section "message"  -> stdout, bold section header
#   log_fatal   "message"  -> stderr, red, exits non-zero
#
# Environment:
#   LOG_LEVEL=ERROR|WARN|INFO|DEBUG|TRACE
#   LOG_SOURCE=name
#   NO_COLOR=1
#   FORCE_COLOR=1
#   LOG_TIMESTAMP_FORMAT='%Y-%m-%d %H:%M:%S'
#
# Notes:
#   - Does not modify shell options in the caller.
#   - Does not require strict mode, but works under set -euo pipefail.
#   - Colors are disabled automatically when stdout/stderr is not a TTY.
# =============================================================================

# -----------------------------------------------------------------------------
# Guard: require Bash
# -----------------------------------------------------------------------------

if [[ -z "${BASH_VERSION:-}" ]]; then
  echo "logger.sh requires Bash." >&2
  return 1 2>/dev/null || exit 1
fi

# -----------------------------------------------------------------------------
# Log levels
# -----------------------------------------------------------------------------

__LOGGER_LEVEL_ERROR=0
__LOGGER_LEVEL_WARN=1
__LOGGER_LEVEL_SUCCESS=2
__LOGGER_LEVEL_INFO=3
__LOGGER_LEVEL_DEBUG=4
__LOGGER_LEVEL_TRACE=5

__LOGGER_INITIALIZED="${__LOGGER_INITIALIZED:-0}"
__LOGGER_NUM_LEVEL="${__LOGGER_NUM_LEVEL:-}"

# -----------------------------------------------------------------------------
# Internal helpers
# -----------------------------------------------------------------------------

__logger_parse_level() {
  local level="${LOG_LEVEL:-INFO}"

  case "${level^^}" in
    ERROR|ERR)
      printf '%s\n' "${__LOGGER_LEVEL_ERROR}"
      ;;
    WARN|WARNING)
      printf '%s\n' "${__LOGGER_LEVEL_WARN}"
      ;;
    SUCCESS|OK)
      printf '%s\n' "${__LOGGER_LEVEL_SUCCESS}"
      ;;
    INFO|"")
      printf '%s\n' "${__LOGGER_LEVEL_INFO}"
      ;;
    DEBUG)
      printf '%s\n' "${__LOGGER_LEVEL_DEBUG}"
      ;;
    TRACE)
      printf '%s\n' "${__LOGGER_LEVEL_TRACE}"
      ;;
    *)
      printf '%s\n' "${__LOGGER_LEVEL_INFO}"
      ;;
  esac
}

__logger_stream_is_tty() {
  local stream="${1:-stdout}"

  case "${stream}" in
    stderr)
      [[ -t 2 ]]
      ;;
    stdout|*)
      [[ -t 1 ]]
      ;;
  esac
}

__logger_colors_enabled() {
  local stream="${1:-stdout}"

  if [[ -n "${NO_COLOR:-}" && "${NO_COLOR:-}" != "0" ]]; then
    return 1
  fi

  if [[ -n "${FORCE_COLOR:-}" && "${FORCE_COLOR:-}" != "0" ]]; then
    return 0
  fi

  if [[ "${TERM:-}" == "dumb" ]]; then
    return 1
  fi

  __logger_stream_is_tty "${stream}"
}

__logger_init_colors() {
  local colors="0"

  # Defaults: no color.
  __LOGGER_C_RESET=""
  __LOGGER_C_BOLD=""
  __LOGGER_C_DIM=""
  __LOGGER_C_RED=""
  __LOGGER_C_YELLOW=""
  __LOGGER_C_GREEN=""
  __LOGGER_C_CYAN=""
  __LOGGER_C_WHITE=""

  if ! __logger_colors_enabled stdout && ! __logger_colors_enabled stderr; then
    return 0
  fi

  if command -v tput >/dev/null 2>&1; then
    colors="$(tput colors 2>/dev/null || printf '0')"

    if [[ "${colors}" =~ ^[0-9]+$ ]] && (( colors >= 8 )); then
      __LOGGER_C_RESET="$(tput sgr0 2>/dev/null || true)"
      __LOGGER_C_BOLD="$(tput bold 2>/dev/null || true)"
      __LOGGER_C_DIM="$(tput dim 2>/dev/null || true)"
      __LOGGER_C_RED="$(__LOGGER_C_BOLD)$(tput setaf 1 2>/dev/null || true)"
      __LOGGER_C_YELLOW="$(__LOGGER_C_BOLD)$(tput setaf 3 2>/dev/null || true)"
      __LOGGER_C_GREEN="$(__LOGGER_C_BOLD)$(tput setaf 2 2>/dev/null || true)"
      __LOGGER_C_CYAN="$(__LOGGER_C_BOLD)$(tput setaf 6 2>/dev/null || true)"
      __LOGGER_C_WHITE="$(__LOGGER_C_BOLD)$(tput setaf 7 2>/dev/null || true)"
      return 0
    fi
  fi

  # ANSI fallback.
  __LOGGER_C_RESET=$'\033[0m'
  __LOGGER_C_BOLD=$'\033[1m'
  __LOGGER_C_DIM=$'\033[2m'
  __LOGGER_C_RED=$'\033[1;31m'
  __LOGGER_C_YELLOW=$'\033[1;33m'
  __LOGGER_C_GREEN=$'\033[1;32m'
  __LOGGER_C_CYAN=$'\033[1;96m'
  __LOGGER_C_WHITE=$'\033[1;97m'
}

logger_init() {
  __LOGGER_NUM_LEVEL="$(__logger_parse_level)"
  __logger_init_colors
  __LOGGER_INITIALIZED=1
}

logger_reset() {
  __LOGGER_INITIALIZED=0
  __LOGGER_NUM_LEVEL=""
  logger_init
}

__logger_source_name() {
  if [[ -n "${LOG_SOURCE:-}" ]]; then
    printf '%s\n' "${LOG_SOURCE}"
    return 0
  fi

  if [[ -n "${BASH_SOURCE[2]:-}" ]]; then
    basename "${BASH_SOURCE[2]}"
    return 0
  fi

  if [[ -n "${BASH_SOURCE[1]:-}" ]]; then
    basename "${BASH_SOURCE[1]}"
    return 0
  fi

  basename "${0:-shell}"
}

__logger_should_emit() {
  local level_num="${1}"

  if [[ "${__LOGGER_INITIALIZED:-0}" != "1" || -z "${__LOGGER_NUM_LEVEL:-}" ]]; then
    logger_init
  fi

  (( level_num <= __LOGGER_NUM_LEVEL ))
}

__logger_timestamp() {
  date +"${LOG_TIMESTAMP_FORMAT:-%Y-%m-%d %H:%M:%S}"
}

__logger_emit() {
  local level_num="${1}"
  local level_name="${2}"
  local color="${3}"
  local stream="${4}"
  shift 4

  local message="$*"
  local timestamp=""
  local source=""
  local prefix=""
  local line=""

  __logger_should_emit "${level_num}" || return 0

  timestamp="$(__logger_timestamp)"
  source="$(__logger_source_name)"
  prefix="[${timestamp}] [${level_name}]"
  line="${prefix} ${source}: ${message}"

  if [[ "${stream}" == "stderr" ]]; then
    if __logger_colors_enabled stderr && [[ -n "${color}" ]]; then
      printf '%b\n' "${color}${prefix}${__LOGGER_C_WHITE} ${source}: ${message}${__LOGGER_C_RESET}" >&2
    else
      printf '%s\n' "${line}" >&2
    fi
  else
    if __logger_colors_enabled stdout && [[ -n "${color}" ]]; then
      printf '%b\n' "${color}${prefix}${__LOGGER_C_WHITE} ${source}: ${message}${__LOGGER_C_RESET}"
    else
      printf '%s\n' "${line}"
    fi
  fi
}

# -----------------------------------------------------------------------------
# Public log helpers
# -----------------------------------------------------------------------------

log_error() {
  [[ "${__LOGGER_INITIALIZED:-0}" == "1" ]] || logger_init
  __logger_emit "${__LOGGER_LEVEL_ERROR}" "ERROR" "${__LOGGER_C_RED}" stderr "$*"
}

log_warn() {
  [[ "${__LOGGER_INITIALIZED:-0}" == "1" ]] || logger_init
  __logger_emit "${__LOGGER_LEVEL_WARN}" "WARN" "${__LOGGER_C_YELLOW}" stderr "$*"
}

log_success() {
  [[ "${__LOGGER_INITIALIZED:-0}" == "1" ]] || logger_init
  __logger_emit "${__LOGGER_LEVEL_SUCCESS}" "SUCCESS" "${__LOGGER_C_GREEN}" stdout "$*"
}

log_info() {
  [[ "${__LOGGER_INITIALIZED:-0}" == "1" ]] || logger_init
  __logger_emit "${__LOGGER_LEVEL_INFO}" "INFO" "${__LOGGER_C_CYAN}" stdout "$*"
}

log_debug() {
  [[ "${__LOGGER_INITIALIZED:-0}" == "1" ]] || logger_init
  __logger_emit "${__LOGGER_LEVEL_DEBUG}" "DEBUG" "${__LOGGER_C_DIM}" stdout "$*"
}

log_trace() {
  [[ "${__LOGGER_INITIALIZED:-0}" == "1" ]] || logger_init
  __logger_emit "${__LOGGER_LEVEL_TRACE}" "TRACE" "${__LOGGER_C_DIM}" stdout "$*"
}

log_section() {
  [[ "${__LOGGER_INITIALIZED:-0}" == "1" ]] || logger_init

  local message="$*"
  local separator="==============================================================================="

  if __logger_colors_enabled stdout && [[ -n "${__LOGGER_C_BOLD}" ]]; then
    printf '%b\n' "${__LOGGER_C_BOLD}${separator}${__LOGGER_C_RESET}"
    printf '%b\n' "${__LOGGER_C_BOLD}${message}${__LOGGER_C_RESET}"
    printf '%b\n' "${__LOGGER_C_BOLD}${separator}${__LOGGER_C_RESET}"
  else
    printf '%s\n' "${separator}"
    printf '%s\n' "${message}"
    printf '%s\n' "${separator}"
  fi
}

log_fatal() {
  local exit_code=1

  if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
    exit_code="${1}"
    shift
  fi

  log_error "$*"
  exit "${exit_code}"
}

# -----------------------------------------------------------------------------
# Direct execution demo
# -----------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    --demo|--example)
      log_section "Logger demo"
      log_error "this is an error"
      log_warn "this is a warning"
      log_success "this is a success"
      log_info "this is informational"
      log_debug "this is debug output; visible with LOG_LEVEL=DEBUG or TRACE"
      log_trace "this is trace output; visible with LOG_LEVEL=TRACE"
      ;;
    *)
      cat <<'EOF'
Usage:
  logger.sh --demo

Environment:
  LOG_LEVEL=ERROR|WARN|INFO|DEBUG|TRACE
  NO_COLOR=1
  FORCE_COLOR=1
  LOG_SOURCE=name
EOF
      ;;
  esac
fi

# =============================================================================
# End of logger.sh
# =============================================================================
