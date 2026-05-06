#!/usr/bin/env bash
# Link the local Supabase CLI to a remote project so migrations can be
# pushed and Edge Functions deployed.
# Usage:  ./scripts/link-supabase.sh <project-ref>
set -euo pipefail
REF="${1:?Pass the Supabase project ref (e.g. abcd1234)}"
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ROOT=$(cd "$HERE/.." && pwd)

cd "$ROOT/backend/supabase"

if ! command -v supabase >/dev/null; then
  echo "Install supabase CLI first: brew install supabase/tap/supabase" >&2
  exit 1
fi

supabase link --project-ref "$REF"
echo "✓ Linked to $REF"
echo
echo "Useful next steps:"
echo "  supabase db push                              # apply local migrations to the remote project"
echo "  supabase secrets set LLM_API_KEY=...          # secret used by reply-suggest"
echo "  supabase secrets set AWS_ACCESS_KEY_ID=...    # secrets used by verify-selfie"
echo "  supabase functions deploy reply-suggest"
