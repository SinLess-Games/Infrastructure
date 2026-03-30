#!/usr/bin/env bash
set -euo pipefail

##############################################################################
# discord.sh
#
# Lightweight helper script to manage the upstream Discord .deb and BetterDiscord
# (via betterdiscordctl). Intended for interactive desktop use where a user
# wants a reproducible install/update flow and a quiet launcher for the
# Discord desktop client.
#
# Key behaviors:
# - `install` downloads the official Discord .deb and installs it via `apt`,
#   then installs BetterDiscord and launches Discord in the background.
# - `update`/`upgrade` behaves like `install` but attempts a BetterDiscord
#   reinstall afterwards (falls back to install if reinstall fails).
# - `bd <action>` forwards to `betterdiscordctl` with a modules directory
#   discovered under $HOME/.config/discord/*/modules and supports status,
#   install, reinstall, uninstall.
# - Running the script with no args launches the Discord binary quietly.
#
# Safety notes:
# - This script calls `sudo` for operations that require root (moving files to
#   /usr/local/bin, apt install). It exits on missing required commands.
# - The script uses `set -euo pipefail` so failures abort early.
##############################################################################

# Official Discord .deb download endpoint (stable) and BetterDiscordctl URL.
DISCORD_DEB_URL="https://discord.com/api/download?platform=linux&format=deb"
BDCTL_URL="https://raw.githubusercontent.com/bb010g/betterdiscordctl/master/betterdiscordctl"


# Load logger utilities (provides log_info/log_warn/log_error)
# Resolve script directory reliably and source `utils/logger.sh` next to this file.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/utils/logger.sh" ]]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/utils/logger.sh"
else
  echo "logger not found at $SCRIPT_DIR/utils/logger.sh" >&2
  exit 1
fi


# Utility: ensure a command exists on PATH. If it's missing, attempt to
# install it via the system package manager. Uses logger for user-facing
# messages (so logger must be sourced above).
need() {
  # If command already exists, we're done
  if command -v "$1" >/dev/null 2>&1; then
    return 0
  fi

  log_warn "Missing command: $1 — attempting to install..."

  # Default package name is the same as the command; override common cases
  pkg="$1"
  case "$1" in
    setsid) pkg=util-linux ;;    # provides setsid on many distros
    pkill) pkg=procps ;;         # provides pkill/pidof/etc
    nohup) pkg=coreutils ;;     # provides nohup
    sudo) pkg=sudo ;;
    apt|apt-get) pkg=apt ;;
    curl) pkg=curl ;;
  esac

  # Try common package managers in order of prevalence. Use sudo for
  # installation; if sudo is missing the earlier branch would have tried to
  # install it (but that requires another package manager). Fail if no
  # supported package manager is present.
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y "$pkg"
  elif command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y "$pkg"
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y "$pkg"
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm "$pkg"
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y "$pkg"
  else
    log_error "No supported package manager found; please install $pkg manually."
    exit 1
  fi

  # Verify the install succeeded
  if command -v "$1" >/dev/null 2>&1; then
    return 0
  fi

  log_error "Install attempted but $1 still missing; please install it manually."
  exit 1
}


# Locate the real Discord binary path. On some installs `/usr/bin/discord` is a
# symlink; we resolve it to the real file and confirm it's executable. If the
# resolution fails we still return the default `/usr/bin/discord` so calling
# code can attempt to run it and surface any errors.
real_discord_bin() {
  local resolved
  resolved="$(readlink -f /usr/bin/discord 2>/dev/null || true)"
  # If resolved and executable, use it; otherwise return the expected path.
  [[ -n "${resolved}" && -x "${resolved}" ]] && echo "${resolved}" || echo /usr/bin/discord
}


# Find the most recent Discord "modules" directory under the user's
# configuration directory. The pattern matches installs like:
#   $HOME/.config/discord/<version>/modules
# We sort by version-like names (using sort -V) and pick the last entry. If no
# modules directory exists, the function returns failure (non-zero) so callers
# can handle the error.
latest_modules_dir() {
  local md
  md="$(printf '%s\n' "$HOME/.config/discord/"*/modules 2>/dev/null | sort -V | tail -n1)"
  [[ -n "${md}" && -d "${md}" ]] || return 1
  echo "${md}"
}


# Ensure `betterdiscordctl` is installed. If it's not present we download the
# bootstrap script to /tmp, make it executable and move it to /usr/local/bin.
# After installation we try a non-fatal `self-upgrade` to keep the tool
# reasonably fresh; failures during self-upgrade are ignored.
ensure_bdctl() {
  if ! command -v betterdiscordctl >/dev/null 2>&1; then
    need curl
    log_info "Downloading betterdiscordctl..."
    curl -fsSL -o /tmp/betterdiscordctl "$BDCTL_URL"
    chmod +x /tmp/betterdiscordctl
    sudo mv /tmp/betterdiscordctl /usr/local/bin/betterdiscordctl
  fi
  # `self-upgrade` may require root depending on where betterdiscordctl lives.
  sudo betterdiscordctl self-upgrade >/dev/null 2>&1 || true
}


# Download and install (or upgrade) the official Discord .deb. We use
# /var/tmp so that APT can access the file (avoids unsandboxed warnings from
# apt's _apt user). This function requires `curl`, `sudo` and `apt` on PATH.
install_or_update_discord() {
  need curl; need sudo; need apt

  # Create a secure temporary directory under /var/tmp and ensure it's
  # removed when the function exits (trap RETURN). Keep the directory
  # permissions permissive enough for apt to read the file.
  local tmpdir deb
  tmpdir="$(mktemp -d /var/tmp/discord.XXXXXX)"
  trap 'rm -rf "$tmpdir"' RETURN
  chmod 755 "$tmpdir"
  deb="$tmpdir/discord.deb"

  log_info "[Discord] Downloading latest .deb..."
  curl -fL "$DISCORD_DEB_URL" -o "$deb"
  chmod 644 "$deb"
  log_info "[Discord] Installing/upgrading..."
  sudo apt install -y "$deb"
}


# Stop any running Discord processes. We attempt two common process patterns and
# ignore errors so stopping is best-effort. This helps when replacing files or
# reinstalling to guarantee files are not locked by a running process.
stop_discord() {
  pkill -x Discord 2>/dev/null || true
  pkill -f '/usr/share/discord/Discord' 2>/dev/null || true
}


# Check whether BetterDiscord is currently injected for a given modules
# directory. Takes one argument: the modules directory path. Returns 0 when
# injected, non-zero otherwise. We silence betterdiscordctl stderr and test
# for the expected status string.
bd_injected() {
  local md="$1"
  betterdiscordctl -m "$md" status 2>/dev/null | grep -q 'Discord "index.js" injected: yes'
}


# Run BetterDiscord actions in a robust way. Parameter is one of:
#   install | reinstall | uninstall | status
# The function will locate the modules directory and call betterdiscordctl
# with the `-m` flag. For `reinstall` we fall back to `install` if the
# reinstall operation fails (common when the plugin was never installed).
run_bd_smart() {
  local desired="$1"  # install|reinstall|uninstall|status
  ensure_bdctl

  local md
  md="$(latest_modules_dir)" || {
    log_error "[BetterDiscord] Could not find Discord modules under: $HOME/.config/discord/*/modules"
    exit 1
  }

  log_info "[BetterDiscord] Using modules: $md"

  case "$desired" in
    status)    betterdiscordctl -m "$md" status ;;
    uninstall) betterdiscordctl -m "$md" uninstall ;;
    install)   betterdiscordctl -m "$md" install ;;
    reinstall)
      # If not injected yet, do install (reinstall will error "Not installed.").
      if ! bd_injected "$md"; then
        betterdiscordctl -m "$md" install
        return
      fi
      # Try reinstall; if it fails, fall back to install to recover gracefully.
      if ! betterdiscordctl -m "$md" reinstall; then
        betterdiscordctl -m "$md" install
      fi
      ;;
    *) log_error "Unknown BetterDiscord action: $desired"; exit 1 ;;
  esac
}


# Launch the Discord binary detached and with all output suppressed. We prefer
# `setsid -f` when available because it more reliably detaches the process
# from the terminal; otherwise we fallback to `nohup`. The function exits the
# script after launching to mimic a GUI launcher behavior.
launch_discord_quiet() {
  local bin
  bin="$(real_discord_bin)"

  if command -v setsid >/dev/null 2>&1; then
    setsid -f "$bin" >/dev/null 2>&1 < /dev/null &
  else
    nohup "$bin" >/dev/null 2>&1 < /dev/null &
  fi

  exit 0
}


# Print the simple usage help text. Kept separate to keep the main dispatch
# logic concise and readable.
usage() {
  cat <<'USAGE'
Usage:
  discord                 Launch Discord (quiet; no terminal logs)
  discord install         Install/upgrade Discord, then install BetterDiscord (quiet launch)
  discord update          Update/upgrade Discord, then reinstall BetterDiscord (quiet launch)
  discord bd status       BetterDiscord status
  discord bd install      Install BetterDiscord
  discord bd reinstall    Reinstall BetterDiscord (or install if missing)
  discord bd uninstall    Uninstall BetterDiscord
USAGE
}


# Main dispatch: parse the first argument and run the appropriate sequence.
case "${1:-}" in
  install)
    stop_discord
    install_or_update_discord
    run_bd_smart install
    launch_discord_quiet
    ;;
  update|upgrade)
    stop_discord
    install_or_update_discord
    run_bd_smart reinstall
    launch_discord_quiet
    ;;
  bd)
    # Forward further bd subcommands to run_bd_smart
    shift || true
    case "${1:-}" in
      status|install|reinstall|uninstall) run_bd_smart "${1}" ;;
      *) usage; exit 1 ;;
    esac
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    # Default action: launch Discord silently
    launch_discord_quiet
    ;;
esac