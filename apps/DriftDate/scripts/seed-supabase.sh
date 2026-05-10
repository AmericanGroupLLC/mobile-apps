#!/usr/bin/env bash
# Boot a local Supabase stack, apply migrations, seed 20 demo profiles.
# Requires: Docker, supabase CLI.
#   brew install supabase/tap/supabase
set -euo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ROOT=$(cd "$HERE/.." && pwd)

green()  { printf "\033[1;32m%s\033[0m\n" "$1"; }

cd "$ROOT/backend/supabase"

if ! command -v supabase >/dev/null; then
  echo "Install supabase CLI first: brew install supabase/tap/supabase" >&2
  exit 1
fi

green "▶ supabase start"
supabase start

green "▶ supabase db reset (applies all migrations + seed)"
# `db reset` automatically loads seed/seed.sql when it exists.
supabase db reset

green "✓ Local Supabase ready."
echo "API URL:        $(supabase status --output env | grep API_URL    | cut -d= -f2-)"
echo "Anon key:       $(supabase status --output env | grep ANON_KEY   | cut -d= -f2-)"
echo "Studio (web UI): http://localhost:54323/"
