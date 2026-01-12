#!/usr/bin/env bash
set -euo pipefail

# Minimal demo script for the sayhello skill.
# Used only to verify that the skills pipeline can execute shell scripts.

NAME="${1:-sayhello}"

echo "hello from sayhello (${NAME})"
