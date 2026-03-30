#!/bin/bash
set -e

export VAULT_ADDR="https://10.10.10.180:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN="{{ vault_token }}"

USERNAME="{{ item.name }}"
VAULT_BIN="/usr/local/bin/vault"

# Check if user already exists
user_exists=$( $VAULT_BIN read -format=json auth/userpass/users/$USERNAME 2>/dev/null | jq -r '.data.username // empty' || echo "" )

if [ -z "$user_exists" ]; then
  echo "Creating user: $USERNAME" >&2
  # Create user with temporary password and policies
  {% if item.policies | length == 1 %}
  $VAULT_BIN write auth/userpass/users/$USERNAME password="temp_pass_${USERNAME}_$(date +%s)" policies="{{ item.policies[0] }}" > /dev/null
  {% else %}
  $VAULT_BIN write auth/userpass/users/$USERNAME password="temp_pass_${USERNAME}_$(date +%s)" policies="{{ item.policies | join(',') }}" > /dev/null
  {% endif %}
else
  echo "User $USERNAME already exists, updating policies" >&2
  # Update user with new policies
  {% if item.policies | length == 1 %}
  $VAULT_BIN write auth/userpass/users/$USERNAME policies="{{ item.policies[0] }}" > /dev/null
  {% else %}
  $VAULT_BIN write auth/userpass/users/$USERNAME policies="{{ item.policies | join(',') }}" > /dev/null
  {% endif %}
fi

# Generate orphan token with policies
{% if item.policies | length == 1 %}
token_output=$( $VAULT_BIN token create -format=json -policy="{{ item.policies[0] }}" -display-name="token_${USERNAME}" -ttl=720h 2>&1 )
{% else %}
# For multiple policies, we create with first policy and add others
token_output=$( $VAULT_BIN token create -format=json -policy="{{ item.policies[0] }}"{% for policy in item.policies[1:] %} -policy="{{ policy }}"{% endfor %} -display-name="token_${USERNAME}" -ttl=720h 2>&1 )
{% endif %}

echo "$token_output"
