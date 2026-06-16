#!/bin/bash

set -e

CONFIG_NAME="system-setup"
SETUP_DIR="$HOME/.system-setup"
PROJECT_URL="https://github.com/prostoLavr/ansible-system-setup.git"
SSH_URL="git@github.com:prostoLavr/ansible-system-setup.git"
BIN_DIR="/usr/local/bin"

check_ssh_and_use_if_available() {
  if ssh -o ConnectTimeout=3 -T git@github.com 2>&1 | grep -q "You've successfully authenticated"; then
    echo "SSH authentication successful. Using SSH URL."
    PROJECT_URL="$SSH_URL"
  fi
}

detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
  else
    echo "Unsupported Linux distribution."
    exit 1
  fi
}

install_packages() {
  case "$OS" in
  ubuntu | debian | pop)
    echo "Updating package lists..."
    sudo apt-get update -y
    echo "Installing Git and Ansible..."
    sudo apt-get install -y git ansible
    ;;
  centos | rhel | rocky | almalinux)
    echo "Enabling EPEL repository..."
    sudo dnf install -y epel-release
    echo "Installing Git and Ansible..."
    sudo dnf install -y git ansible
    ;;
  fedora)
    echo "Installing Git and Ansible..."
    sudo dnf install -y git ansible
    ;;
  arch | manjaro)
    echo "Updating repositories and installing Git and Ansible..."
    sudo pacman -Syu --noconfirm git ansible
    ;;
  *)
    echo "OS '$OS' is not explicitly supported by this script."
    exit 1
    ;;
  esac
}

detect_os

INSTALL_NEEDED=false

if ! command -v git &>/dev/null; then
  echo "Git is not installed. Proceeding with installation..."
  INSTALL_NEEDED=true
else
  echo "Git is already installed: $(git --version)"
fi

if ! command -v ansible &>/dev/null; then
  echo "Ansible is not installed. Proceeding with installation..."
  INSTALL_NEEDED=true
else
  echo "Ansible is already installed: $(ansible --version | head -n 1)"
fi

if [ "$INSTALL_NEEDED" = true ]; then
  install_packages
  echo "Verification after installation:"
  git --version
  ansible --version
else
  echo "All prerequisites are already met!"
fi

check_ssh_and_use_if_available

if [ ! -d "$SETUP_DIR" ]; then
  git clone "$PROJECT_URL" "$SETUP_DIR"
  cd "$SETUP_DIR"
else
  cd "$SETUP_DIR"
  git remote set-url origin "$PROJECT_URL"
  git pull
  git reset --hard main
fi

if ! sudo test -f "$BIN_DIR/$CONFIG_NAME"; then
  echo "Copy binary link into $BIN_DIR"
else
  echo "Update binary link in $BIN_DIR"
fi
sudo ln -fs "$SETUP_DIR/configure.sh" "$BIN_DIR/$CONFIG_NAME"

sudo chmod 755 "$SETUP_DIR/configure.sh"

sudo chown -h root:root "$BIN_DIR/$CONFIG_NAME"

echo "Done. Read README.md or try system-setup help"
