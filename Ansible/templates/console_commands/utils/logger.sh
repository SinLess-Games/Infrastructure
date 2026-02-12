#!/usr/bin/env bash
set -euo pipefail

##############################################################################
# logger.sh
#
# Simple, reusable Bash logger providing consistent, colored output with
# timestamp, level, and source. Colors can be disabled with `NO_COLOR=1` or on
# terminals that don't support color. Default level is `INFO`; set `LOG_LEVEL`
# to one of ERROR,WARN,INFO,DEBUG to change verbosity.
#
# Exposed functions:
#   log_error "message"   -> red, goes to stderr
#   log_warn  "message"   -> yellow, goes to stderr
#   log_info  "message"   -> light blue, goes to stdout
#   log_debug "message"   -> dim/default, goes to stdout (only when LOG_LEVEL=DEBUG)
#
##############################################################################

# Level numeric values (lower is more severe)
declare -r _LOG_LVL_ERROR=0
declare -r _LOG_LVL_WARN=1
declare -r _LOG_LVL_INFO=2
declare -r _LOG_LVL_DEBUG=3

# Map LOG_LEVEL env var (string) to numeric level. Default: INFO
_parse_log_level() {
  local lvl
  lvl="${LOG_LEVEL:-INFO}"
  case "${lvl^^}" in
    ERROR) echo "${_LOG_LVL_ERROR}" ;;
    WARN|WARNING) echo "${_LOG_LVL_WARN}" ;;
    DEBUG) echo "${_LOG_LVL_DEBUG}" ;;
    *) echo "${_LOG_LVL_INFO}" ;;
  esac
}

# Determine if colors should be used. Honor NO_COLOR env var and TERM=dumb.
_colors_enabled() {
  if [[ "${NO_COLOR:-}" != "" && "${NO_COLOR:-}" != "0" ]]; then
    return 1
  fi
  if [[ "${TERM:-}" = "dumb" ]]; then
    return 1
  fi
  # stdout is a terminal? If not, fall back to disabling colors to keep logs
  # clean when redirected.
  if [[ ! -t 1 ]]; then
    return 1
  fi
  return 0
}

# Initialize color variables (called once lazily)
_logger_init() {
  if _colors_enabled; then
    # Prefer terminal capabilities via `tput` (safer across terminals/themes).
    if command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1 && [ "$(tput colors)" -ge 8 ] 2>/dev/null; then
      local T_BOLD T_RESET T_RED T_YELLOW T_CYAN T_WHITE T_DIM
      T_BOLD="$(tput bold 2>/dev/null || true)"
      T_RESET="$(tput sgr0 2>/dev/null || true)"
      T_RED="$(tput setaf 1 2>/dev/null || true)"
      T_YELLOW="$(tput setaf 3 2>/dev/null || true)"
      # Use cyan for info (terminal color index 6)
      T_CYAN="$(tput setaf 6 2>/dev/null || true)"
      T_WHITE="$(tput setaf 7 2>/dev/null || true)"
      T_DIM="$(tput dim 2>/dev/null || true)"

      _C_RED="${T_BOLD}${T_RED}"
      _C_YELLOW="${T_BOLD}${T_YELLOW}"
      _C_LIGHT_BLUE="${T_BOLD}${T_CYAN}"
      _C_DIM="${T_DIM}"
      _C_WHITE="${T_BOLD}${T_WHITE}"
      _C_RESET="${T_RESET}"
    else
      # Fallback to ANSI escapes when tput isn't available or term lacks colors
      _C_RED="\033[1;31m"
      _C_YELLOW="\033[1;33m"
      _C_LIGHT_BLUE="\033[1;96m"
      _C_DIM="\033[2m"
      # White for message body after the level
      _C_WHITE="\033[1;97m"
      _C_RESET="\033[0m"
    fi
  else
    _C_RED=""
    _C_YELLOW=""
    _C_LIGHT_BLUE=""
    _C_DIM=""
    _C_WHITE=""
    _C_RESET=""
  fi

  # Cache numeric level
  _LOG_NUM_LEVEL="$(_parse_log_level)"
}

# Internal: format and emit a log line. Parameters:
#   $1 = numeric level
#   $2 = level name (e.g. ERROR)
#   $3 = color code to use
#   $4 = stream: stdout|stderr
#   $5 = message
_log_emit() {
  local lvl_num="$1" lvl_name="$2" color="$3" stream="$4" msg="$5"
  # Lazy init
  [[ -n "${_LOG_NUM_LEVEL:-}" ]] || _logger_init

  # Decide whether to print based on numeric level
  if (( lvl_num > _LOG_NUM_LEVEL )); then
    return 0
  fi

  local ts
  ts="$(date +'%Y-%m-%d %H:%M:%S')"

  # Compose formatted message: [TIMESTAMP] [LEVEL] source: message
  local src
  src="$(basename "${0:-}")"

  local prefix rest formatted
  prefix="[${ts}] [${lvl_name}]"
  rest=" ${src}: ${msg}"
  formatted="${prefix}${rest}"

  local body_color
  # For ERROR level we want the whole line in the level color for visibility.
  if (( lvl_num == _LOG_LVL_ERROR )); then
    body_color="$color"
  else
    body_color="${_C_WHITE:-}"
  fi

  if [[ "$stream" = stdout ]]; then
    if [[ -n "$color" ]]; then
      # Color the prefix (timestamp+level) with the requested color and the
      # message body in `body_color` (white for most levels, red for ERROR).
      printf '%b\n' "${color}${prefix}${body_color}${rest}${_C_RESET:-}"
    else
      printf '%s\n' "${formatted}"
    fi
  else
    if [[ -n "$color" ]]; then
      printf '%b\n' "${color}${prefix}${body_color}${rest}${_C_RESET:-}" >&2
    else
      printf '%s\n' "${formatted}" >&2
    fi
  fi
}

# Public helpers
log_error() {
  # Ensure logger initialized so color variables are set
  [[ -n "${_LOG_NUM_LEVEL:-}" && -n "${_C_RED:-}" ]] || _logger_init
  _log_emit ${_LOG_LVL_ERROR} "ERROR" "${_C_RED}" stderr "$*"
}

log_warn() {
  [[ -n "${_LOG_NUM_LEVEL:-}" && -n "${_C_YELLOW:-}" ]] || _logger_init
  _log_emit ${_LOG_LVL_WARN} "WARN" "${_C_YELLOW}" stderr "$*"
}

log_info() {
  [[ -n "${_LOG_NUM_LEVEL:-}" && -n "${_C_LIGHT_BLUE:-}" ]] || _logger_init
  _log_emit ${_LOG_LVL_INFO} "INFO" "${_C_LIGHT_BLUE}" stdout "$*"
}

log_debug() {
  [[ -n "${_LOG_NUM_LEVEL:-}" && -n "${_C_DIM:-}" ]] || _logger_init
  _log_emit ${_LOG_LVL_DEBUG} "DEBUG" "${_C_DIM}" stdout "$*"
}

# If the script is invoked directly with `--demo` or `--example`, print a
# short demo to show colors/formatting. This helps when validating the
# behaviour while editing the template.
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
  case "${1:-}" in
    --demo|--example)
      echo "Logger demo (LOG_LEVEL=${LOG_LEVEL:-INFO}, NO_COLOR=${NO_COLOR:-})"
      echo ""
      echo ""
      log_error "this is an error"
      log_warn  "this is a warning"
      log_info  "this is informational"
      log_debug "this is debug (visible only when LOG_LEVEL=DEBUG)"
      exit 0
      ;;
  esac
fi

##############################################################################
# End of logger.sh
##############################################################################
