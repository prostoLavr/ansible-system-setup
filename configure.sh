#!/bin/bash
set -e

PROJECT_PATH="$HOME/.system-setup/"
PROJECT_URL="git@github.com:prostoLavr/ansible-system-setup.git"
INVENTORY_FILE="inventory.yml"
VAULT_PASS_FILE=".vault_pass"

if [ ! -d "$PROJECT_PATH" ]; then
  git clone "$PROJECT_URL" "$PROJECT_PATH"
fi

cd "$PROJECT_PATH"

if [ ! -f "$INVENTORY_FILE" ]; then
  echo "Creating a new secured inventory file..."

  read -sp "Enter the password for your local machine: " SERVER_PASS
  echo ""

  read -sp "Enter a NEW password to secure your Ansible Vault: " VAULT_PASS
  echo ""

  echo -n "$VAULT_PASS" >"$VAULT_PASS_FILE"
  chmod 600 "$VAULT_PASS_FILE"

  echo -n "Encrypting your local machine password..."
  ENCRYPTED_PASS=$(echo -n "$SERVER_PASS" | ansible-vault encrypt_string \
    --vault-password-file="$VAULT_PASS_FILE" \
    --stdin-name 'ansible_sudo_pass')
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

ansible-playbook -i "$INVENTORY_FILE" setup-playbook.yml --ask-vault-pass
