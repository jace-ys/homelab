#!/usr/bin/env bash
set -euo pipefail

K3S_DIR="$HOME/.k3s"
mkdir -p "$K3S_DIR"

stacks=$(spacectl stack list -o json | jq -c '.[] | select(.labels | index("component:k3s"))')
echo "$stacks" | while read -r stack; do
  stack_id=$(echo "$stack" | jq -r '.id')
  stack_name=$(echo "$stack" | jq -r '.name')

  echo ""
  echo "━━━ 🌳 $stack_name ━━━"

  outputs=$(spacectl stack outputs --id "$stack_id" -o json 2>/dev/null || true)
  if [[ -z "$outputs" ]]; then
    continue
  fi

  k3s_output=$(echo "$outputs" | jq -r '.[] | select(.id == "k3s") | .value' 2>/dev/null || true)
  if [[ -z "$k3s_output" || "$k3s_output" == "null" ]]; then
    continue
  fi

  bucket=$(echo "$k3s_output" | jq -r '.kubeconfig.bucket')
  objects=$(echo "$k3s_output" | jq -r '.kubeconfig.objects[]')

  echo "$objects" | while read -r object; do
    created_at=$(oci os object head --bucket-name "$bucket" --name "$object" 2>/dev/null | jq -r '.["last-modified"]')
    echo ""
    echo "Found: $object"
    echo "↪ ⏱️ Updated: $created_at"
    oci os object get \
      --bucket-name "$bucket" \
      --name "$object" \
      --file "$K3S_DIR/$object" >/dev/null 2>&1
    echo "↪ 📁 Saved: $K3S_DIR/$object"
  done
done
