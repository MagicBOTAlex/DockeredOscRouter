#!/bin/sh

echo "[Backend BOOT] Entered repo"
cd /backend/

echo "[Backend BOOT] Starting using nix flake..."
nix run --extra-experimental-features nix-command --extra-experimental-features flakes
