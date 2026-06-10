#!/usr/bin/env bash

K3S_DIR="$HOME/.k3s"

if [[ -d "$K3S_DIR" ]]; then
  KUBECONFIG="$(find "$K3S_DIR" -type f | sort | paste -sd ':' -)"
  [[ -n "$KUBECONFIG" ]] && export KUBECONFIG
fi
