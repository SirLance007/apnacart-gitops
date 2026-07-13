#!/bin/bash
set -e

echo "=== 🔐 Configuring HashiCorp Vault inside vault-0 Pod ==="

# 1. Store the secret in Vault KV engine
echo "-> 1. Writing Database Secrets to secret/apnacart/db-creds..."
kubectl exec -n vault vault-0 -- vault kv put secret/apnacart/db-creds \
  username="apnacart_db_user" \
  password="SuperSecurePassword123!"

# 2. Enable Kubernetes authentication engine
echo "-> 2. Enabling Kubernetes Auth Method..."
kubectl exec -n vault vault-0 -- vault auth enable kubernetes || true

# 3. Configure Kubernetes Auth config
echo "-> 3. Configuring Vault to communicate with Kubernetes API Server..."
kubectl exec -n vault vault-0 -- vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc.cluster.local:443"

# 4. Create Policy for ApnaCart
echo "-> 4. Creating 'apnacart-policy' in Vault..."
kubectl exec -i -n vault vault-0 -- vault policy write apnacart-policy - <<EOF
path "secret/data/apnacart/db-creds" {
  capabilities = ["read"]
}
EOF

# 5. Create Vault Role binding to Service Account
echo "-> 5. Binding 'apnacart-sa' ServiceAccount to 'apnacart-policy'..."
kubectl exec -n vault vault-0 -- vault write auth/kubernetes/role/apnacart-role \
  bound_service_account_names=apnacart-sa \
  bound_service_account_namespaces=default \
  policies=apnacart-policy \
  ttl=24h

echo "=== 🎉 Vault Configured Successfully! ==="
