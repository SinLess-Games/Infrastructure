#!/usr/bin/env bash
# Packer/scripts/installers/qemu-guest-agent.sh
# Installs and enables QEMU Guest Agent in a Debian/Ubuntu-based guest VM.

set -euo pipefail
LOGFILE="/var/log/qemu-guest-agent-install.log"

echo "=== QEMU Guest Agent installer started: $(date) ===" | tee -a "$LOGFILE"

# Update package lists
echo "Updating apt repositories…" | tee -a "$LOGFILE"
apt-get update -qq | tee -a "$LOGFILE"

# Install qemu-guest-agent
echo "Installing qemu-guest-agent…" | tee -a "$LOGFILE"
DEBIAN_FRONTEND=noninteractive apt-get install -yq qemu-guest-agent | tee -a "$LOGFILE"

# Attempt to enable & start the service
echo "Enabling qemu-guest-agent service…" | tee -a "$LOGFILE"
if systemctl list-unit-files | grep -q "^qemu-guest-agent.service"; then
  systemctl enable qemu-guest-agent | tee -a "$LOGFILE" || true
  systemctl restart qemu-guest-agent | tee -a "$LOGFILE" || true
else
  echo "Warning: qemu-guest-agent.service unit not found — may be a static service. Continuing." | tee -a "$LOGFILE"
fi

# Wait a few seconds, then check status
sleep 2
echo "Checking qemu-guest-agent status…" | tee -a "$LOGFILE"
systemctl is-active qemu-guest-agent &>/dev/null
if [ $? -eq 0 ]; then
  echo "qemu-guest-agent is running." | tee -a "$LOGFILE"
else
  echo "qemu-guest-agent failed to start — checking journal for clues." | tee -a "$LOGFILE"
  journalctl -u qemu-guest-agent --no-pager | tail -n 20 | tee -a "$LOGFILE"
  echo "If running under a hypervisor, ensure QEMU Guest Agent channel is enabled on the host side." | tee -a "$LOGFILE"
fi

# Clean up apt cache (optional)
echo "Cleaning up apt cache…" | tee -a "$LOGFILE"
apt-get clean -qq

echo "=== QEMU Guest Agent install script finished: $(date) ===" | tee -a "$LOGFILE"
