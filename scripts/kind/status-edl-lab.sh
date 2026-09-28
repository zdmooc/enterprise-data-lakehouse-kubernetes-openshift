#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
k get nodes -o wide
k get namespaces
k get pods,services,pvc -A
resource_check
