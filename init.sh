#!/bin/bash

CONFIG_NAME="configure.sh"

if ((EUID != 0)); then
  echo "Error: This script must be run as root." >&2
  exit 1
fi

dnf install -y ansible
echo "Copy configure.sh into /usr/local/bin/"
cp configure.sh "/usr/local/bin/$CONFIG_NAME"
chown root:root "/usr/local/bin/$CONFIG_NAME"
chmod 755 "/usr/local/bin/$CONFIG_NAME"
echo "Done."
