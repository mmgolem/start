#!/usr/bin/env bash
# start.sh: turns a fresh Ubuntu 24.04+ or Debian 13+ machine (x86) into Golem. Run as root, in a terminal:
#
#   curl -fsSL https://raw.githubusercontent.com/mmgolem/start/main/start.sh | bash
#
# It makes the user golem (sudo without a password, root's SSH keys), installs git and gh, signs gh in to
# GitHub (a code to enter at github.com/login/device), clones the private mmgolem/setup and runs its
# bootstrap.sh as golem. Everything else lives in that repo, so this file stays small and rarely changes.
# Safe to run again.
set -euo pipefail

# All of it is one function, called on the last line: under curl | bash, bash reads the script from the
# pipe while it runs, so nothing starts before the whole file has arrived.
main() {
  [[ $EUID -eq 0 ]] || { echo "start.sh: run this as root" >&2; exit 1; }
  # The prompts (GitHub's code, the age key, a few questions) read the terminal, not the pipe the script
  # came in on.
  if ! (: </dev/tty) 2>/dev/null; then echo "start.sh: needs a terminal for its prompts; run it in an SSH session (ssh -t)" >&2; exit 1; fi

  # First, so /etc/sudoers.d is there on an image that comes without sudo.
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq sudo git gh curl ca-certificates >/dev/null

  id golem >/dev/null 2>&1 || useradd -m -s /bin/bash golem
  echo 'golem ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/golem
  chmod 440 /etc/sudoers.d/golem
  # The keys that let you in as root let you in as golem; run through sudo, the keys of whoever ran it.
  local keys=/root/.ssh/authorized_keys
  [[ -s "$keys" || -z "${SUDO_USER:-}" ]] || keys="$(getent passwd "$SUDO_USER" | cut -d: -f6)/.ssh/authorized_keys"
  install -d -m 700 -o golem -g golem /home/golem/.ssh
  if [[ -s "$keys" && ! -s /home/golem/.ssh/authorized_keys ]]; then
    install -m 600 -o golem -g golem "$keys" /home/golem/.ssh/authorized_keys
  fi

  # As golem from here. bootstrap.sh switches GitHub to Golem's own token once the age key unlocks it, so
  # this login only has to read mmgolem/setup.
  sudo -u golem -H bash -c '
    set -euo pipefail
    cd ~
    gh auth status >/dev/null 2>&1 || gh auth login --hostname github.com --git-protocol https --web
    gh auth setup-git
    if [[ -d ~/setup/.git ]]; then git -C ~/setup pull -q --ff-only || true
    else gh repo clone mmgolem/setup ~/setup; fi
    exec ~/setup/bootstrap.sh
  ' </dev/tty
}

main "$@"
