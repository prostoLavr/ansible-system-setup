#!/bin/bash

set -e

CONFIG_NAME="configure.sh"
SETUP_DIR="$HOME/.system-setup"
PROJECT_URL="git@github.com:prostoLavr/ansible-system-setup.git"

#!/bin/bash

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

git clone "$PROJECT_URL" "$SETUP_DIR"
echo "Copy binary into /usr/local/bin/"
sudo ln -s "$SETUP_DIR/.configure.sh" "/usr/local/bin/$CONFIG_NAME"
sudo chown root:root "/usr/local/bin/$CONFIG_NAME"
sudo chmod 755 "/usr/local/bin/$CONFIG_NAME"
echo "Done."
