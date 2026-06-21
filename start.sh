#!/usr/bin/env bash
# Sportago Flutter dev: boot the backend (docker compose) then run THIS Flutter app
# against the local BE — one command.
#
# Usage:
#   ./start.sh                # auto-pick a booted iOS simulator (or let Flutter prompt)
#   ./start.sh <device-id>    # run on a specific `flutter devices` id (sim udid / emulator-xxxx)
#
# Env overrides:
#   BE_DIR=/path/to/be-main-fresh   # backend repo (default below)
#   DEV_MODE=ios|android|staging    # which API the app targets (default: auto from device)
#   STOP_BE_ON_EXIT=1               # tear down BE containers when the app exits (default: leave up)
set -euo pipefail

BE_DIR="${BE_DIR:-/Users/okta/Documents/Important/be-main-fresh}"
BE_URL="http://localhost:8088"

C_RESET="\033[0m"; C_GREEN="\033[1;32m"; C_YELLOW="\033[1;33m"; C_RED="\033[1;31m"; C_DIM="\033[2m"
log()  { printf "${C_GREEN}→${C_RESET} %s\n" "$*"; }
warn() { printf "${C_YELLOW}!${C_RESET} %s\n" "$*"; }
die()  { printf "${C_RED}✗${C_RESET} %s\n" "$*" >&2; exit 1; }

# ---- preflight -------------------------------------------------------------
command -v docker  >/dev/null 2>&1 || die "docker not found. Install Docker Desktop first."
command -v flutter >/dev/null 2>&1 || die "flutter not found in PATH."
docker info >/dev/null 2>&1        || die "docker daemon not running. Start Docker Desktop."
[ -d "$BE_DIR" ]                   || die "BE dir missing: $BE_DIR (override with BE_DIR=...)."
[ -f "$BE_DIR/src/.env" ]          || warn "BE .env not found at $BE_DIR/src/.env — compose may fail."

# ---- pick target device ----------------------------------------------------
DEVICE="${1:-}"
if [ -z "$DEVICE" ]; then
  # prefer a booted iOS simulator
  BOOTED_SIM="$(xcrun simctl list devices booted 2>/dev/null | grep -oE '[0-9A-F-]{36}' | head -1 || true)"
  if [ -n "$BOOTED_SIM" ]; then
    DEVICE="$BOOTED_SIM"
    log "Using booted iOS simulator: $DEVICE"
  else
    warn "No device id given and no booted iOS simulator — Flutter will prompt."
  fi
fi

# ---- decide which API the app should hit -----------------------------------
# Local BE only reachable as localhost (ios sim) or 10.0.2.2 (android emu).
if [ -z "${DEV_MODE:-}" ]; then
  case "$DEVICE" in
    emulator-*|*android*) DEV_MODE="android" ;;
    *)                    DEV_MODE="ios" ;;
  esac
fi
log "App will target DEV_MODE=$DEV_MODE (local BE at $BE_URL)"

# ---- cleanup ---------------------------------------------------------------
cleanup() {
  echo ""
  if [ "${STOP_BE_ON_EXIT:-0}" = "1" ]; then
    log "Stopping BE containers..."
    (cd "$BE_DIR" && docker compose down) || true
  else
    printf "${C_DIM}BE still running at %s — stop it with: (cd %s && docker compose down)${C_RESET}\n" "$BE_URL" "$BE_DIR"
  fi
}
trap cleanup INT TERM EXIT

# ---- boot BE ---------------------------------------------------------------
log "Booting BE (docker compose up -d) in $BE_DIR ..."
(cd "$BE_DIR" && docker compose up -d)

log "Waiting for BE on $BE_URL (timeout 90s)..."
for i in $(seq 1 45); do
  if curl -sfo /dev/null --max-time 2 "$BE_URL/up" 2>/dev/null \
     || curl -sfo /dev/null --max-time 2 "$BE_URL" 2>/dev/null; then
    printf "\n"; log "BE responding."; break
  fi
  printf "."; sleep 2
  if [ "$i" -eq 45 ]; then
    printf "\n"; warn "BE didn't respond in time. Recent logs:"
    (cd "$BE_DIR" && docker compose logs --tail=30 app) || true
    die "Aborting. Check 'docker compose logs -f app' in $BE_DIR."
  fi
done

# ---- seed admin (idempotent) ----------------------------------------------
log "Ensuring DB is seeded (idempotent)..."
if (cd "$BE_DIR" && docker compose exec -T app php artisan db:seed --force --no-interaction) >/dev/null 2>&1; then
  printf "  ${C_DIM}admin: support+admin@sportago.id / password${C_RESET}\n"
else
  warn "Seeder skipped (DB not ready yet, or already seeded)."
fi

# ---- run the Flutter app ---------------------------------------------------
echo ""
log "BE ready at ${C_YELLOW}$BE_URL${C_RESET}"
log "Starting Flutter app (Ctrl+C to stop the app; BE keeps running)"
echo ""

cd "$(dirname "$0")"
flutter pub get
if [ -n "$DEVICE" ]; then
  exec flutter run -d "$DEVICE" --dart-define=DEV_MODE="$DEV_MODE"
else
  exec flutter run --dart-define=DEV_MODE="$DEV_MODE"
fi
