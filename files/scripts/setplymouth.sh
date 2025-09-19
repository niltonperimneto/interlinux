#!/usr/bin/env bash
set -euo pipefail

THEME="${1:-school-bgrt}"
THEME_DIR="/usr/share/plymouth/themes/${THEME}"

print()  { printf "%b\n" "$*"; }
info()   { print "\033[1;34m[INFO]\033[0m  $*"; }
ok()     { print "\033[1;32m[ OK ]\033[0m  $*"; }
warn()   { print "\033[1;33m[WARN]\033[0m  $*"; }
err()    { print "\033[1;31m[ERR]\033[0m  $*"; }

require_root() {
  if [[ $EUID -ne 0 ]]; then
    err "Please run as root. Example: sudo $0 ${THEME}"
    exit 1
  fi
}

check_requirements() {
  if ! command -v plymouth >/dev/null 2>&1 && ! command -v plymouth-set-default-theme >/dev/null 2>&1; then
    err "Plymouth is not installed. Install Plymouth and your theme, then retry."
    err "  Debian/Ubuntu: sudo apt install plymouth"
    err "  Fedora/RHEL:   sudo dnf install plymouth"
    err "  Arch:          sudo pacman -S plymouth"
    exit 1
  fi
  if [[ ! -d "${THEME_DIR}" ]]; then
    err "Theme directory not found: ${THEME_DIR}"
    err "Make sure the 'school-bgrt' theme is installed."
    exit 1
  fi
  PLY_FILE="$(find "${THEME_DIR}" -maxdepth 1 -type f -name '*.plymouth' | head -n1 || true)"
  if [[ -z "${PLY_FILE}" ]]; then
    err "No .plymouth file found in ${THEME_DIR}."
    exit 1
  fi
}

show_current_theme() {
  local cur
  cur="$(plymouth-set-default-theme 2>/dev/null || true)"
  if [[ -n "${cur}" ]]; then
    info "Current default theme: ${cur}"
  else
    info "Current default theme: (unknown)"
  fi
}

set_theme_with_tool() {
  if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    info "Setting theme via plymouth-set-default-theme..."
    if plymouth-set-default-theme "${THEME}"; then
      ok "Theme set to '${THEME}'."
      return 0
    else
      warn "plymouth-set-default-theme failed. Falling back…"
    fi
  else
    warn "plymouth-set-default-theme not available. Falling back…"
  fi

  if command -v update-alternatives >/dev/null 2>&1; then
    info "Using update-alternatives…"
    if ! update-alternatives --query default.plymouth >/dev/null 2>&1; then
      update-alternatives --install \
        /usr/share/plymouth/themes/default.plymouth \
        default.plymouth \
        "${PLY_FILE}" 100
    fi
    update-alternatives --set default.plymouth "${PLY_FILE}"
    ok "Theme set via update-alternatives."
    return 0
  fi

  if command -v alternatives >/dev/null 2>&1; then
    info "Using alternatives (RHEL/Fedora)…"
    if ! alternatives --display default.plymouth >/dev/null 2>&1; then
      alternatives --install \
        /usr/share/plymouth/themes/default.plymouth \
        default.plymouth \
        "${PLY_FILE}" 100
    fi
    alternatives --set default.plymouth "${PLY_FILE}"
    ok "Theme set via alternatives."
    return 0
  fi

  info "Updating /etc/plymouth/plymouthd.conf…"
  mkdir -p /etc/plymouth
  if [[ -f /etc/plymouth/plymouthd.conf ]]; then
    if grep -q '^Theme=' /etc/plymouth/plymouthd.conf; then
      sed -i "s/^Theme=.*/Theme=${THEME}/" /etc/plymouth/plymouthd.conf
    else
      awk -v THEME="${THEME}" '
        BEGIN {done=0}
        /^\[Daemon\]/ {print; print "Theme=" THEME; done=1; next}
        {print}
        END {if(!done) print "[Daemon]\nTheme=" THEME}
      ' /etc/plymouth/plymouthd.conf > /etc/plymouth/plymouthd.conf.new && \
      mv /etc/plymouth/plymouthd.conf.new /etc/plymouth/plymouthd.conf
    fi
  else
    printf "[Daemon]\nTheme=%s\n" "${THEME}" > /etc/plymouth/plymouthd.conf
  fi
  ok "Theme recorded in plymouthd.conf."
}

rebuild_initramfs() {
  info "Regenerating initramfs (this may take a moment)…"
  if command -v update-initramfs >/dev/null 2>&1; then
    update-initramfs -u
    ok "initramfs rebuilt via update-initramfs."
    return
  fi
  if command -v dracut >/dev/null 2>&1; then
    dracut -f
    ok "initramfs rebuilt via dracut."
    return
  fi
  if command -v mkinitcpio >/dev/null 2>&1; then
    if compgen -G "/etc/mkinitcpio.d/*.preset" >/dev/null; then
      mkinitcpio -P
    else
      mkinitcpio -g /boot/initramfs-linux.img
    fi
    ok "initramfs rebuilt via mkinitcpio."
    return
  fi
  if command -v plymouth-set-default-theme >/dev/null 2>&1 && \
     plymouth-set-default-theme -R "${THEME}" >/dev/null 2>&1; then
    ok "initramfs rebuilt via plymouth-set-default-theme -R."
    return
  fi
  warn "Could not detect a tool to rebuild initramfs automatically."
  warn "Please rebuild initramfs manually for your distro."
}

main() {
  require_root
  check_requirements
  show_current_theme
  set_theme_with_tool
  rebuild_initramfs
  local new
  new="$(plymouth-set-default-theme 2>/dev/null || true)"
  if [[ -n "${new}" ]]; then
    ok "New default theme: ${new}"
  else
    ok "Theme set to ${THEME}."
  fi
  info "Reboot to see the new splash screen."
  info "If you don't see it, ensure your kernel cmdline includes 'quiet splash' (Ubuntu/Debian) or 'rhgb quiet' (Fedora/RHEL)."
}

main "$@"
