#!/bin/bash
set -e

PROJECT_PATH="$HOME/.system-setup/"
INVENTORY_FILE="inventory.yml"
VAULT_PASS_FILE=".vault_pass"

cd "$PROJECT_PATH"
command_list=("update" "install" "recreate-inventory")
command_found=0
for item in "${command_list[@]}"; do
  if [[ "$item" == "$1" ]]; then
    command_found=1
    break
  fi
done
if ((!command_found)); then
  echo "Usage: system-setup COMMAND"
  echo "Commands:"
  echo "  update                update installation"
  echo "  install               run configuring system"
  echo "  recreate-inventory    recreate inventory file"
  exit 0
fi

if [[ "$1" == "update" ]]; then
  git pull
  git reset --hard main
fi

if [[ "$1" == "install" ]] && [ ! -f "$INVENTORY_FILE" ] || [[ "$1" == "recreate-inventory" ]]; then
  echo "Creating a new secured inventory file..."

  read -sp "Enter the password for your local machine: " SERVER_PASS
  echo ""

  read -sp "Enter a NEW password to secure your Ansible Vault: " VAULT_PASS
  echo ""

  echo -n "$VAULT_PASS" >"$VAULT_PASS_FILE"
  chmod 600 "$VAULT_PASS_FILE"

  echo -n "Encrypting your local machine password..."
  ENCRYPTED_PASS=$(echo -n "$SERVER_PASS" | ansible-vault encrypt_string --vault-password-file="$VAULT_PASS_FILE" --stdin-name 'ansible_sudo_pass')
  echo " Done."

  cat <<EOF >"$INVENTORY_FILE"
all:
  hosts:
    localhost:
      ansible_connection: local
      ansible_python_interpreter: /usr/bin/python3
      $ENCRYPTED_PASS
EOF

  rm -f "$VAULT_PASS_FILE"

  echo "Success! Secured '$INVENTORY_FILE' has been created."
fi

if [[ "$1" == "install" ]]; then
  ansible-playbook -i "$INVENTORY_FILE" setup-playbook.yml --ask-vault-pass
fi
