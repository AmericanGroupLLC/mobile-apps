// Drift Edge Function: wipe-me
//
// GDPR-style account-delete endpoint. Wipes every row a user owns from
// the public schema, then removes the auth.users row last so that
// `auth.users` referential integrity is preserved during the per-table
// deletes (which all cascade ON DELETE from auth.users anyway — see
// 0001_init.sql — but we also delete explicitly for defense-in-depth).
//
// Inputs:  POST with `Authorization: Bearer <user-jwt>`. Body ignored.
// Outputs: 200 { deleted: true, user_id, tables: [...] }
//          401 if the JWT is missing/invalid
//          5xx if `auth.admin.deleteUser` fails (transient — safe to retry)
//
// Deploy:  supabase functions deploy wipe-me --project-ref <ref>
//
// SECURITY: This function uses the service-role key to perform the
// deletes. It MUST verify the bearer JWT first and only delete rows
// owned by the JWT subject — never accept a user_id from the request
// body. The service-role key NEVER leaves the function.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Tables in dependency order (children before parents). All have a
// per-row owner column referencing auth.users(id). photos / prompts /
// messages / conversations / waves / reports / blocked_users all
// cascade on profile delete, but we wipe explicitly for an audit trail
// and so the function is correct even if a future migration drops a
// cascade.
const TABLES_TO_WIPE: ReadonlyArray<{ name: string; col: string }> = [
  { name: "messages",       col: "author_id" },
  { name: "conversations",  col: "profile_a_id" },
  { name: "conversations",  col: "profile_b_id" },
  { name: "waves",          col: "from_profile_id" },
  { name: "waves",          col: "to_profile_id" },
  { name: "wave_aggregates", col: "profile_id" },
  { name: "reports",        col: "reporter_id" },
  { name: "reports",        col: "target_id" },
  { name: "blocked_users",  col: "blocker_id" },
  { name: "blocked_users",  col: "blocked_id" },
  { name: "photos",          col: "profile_id" },
  { name: "profile_prompts", col: "profile_id" },
  { name: "profiles",        col: "id" },
];

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST")    return jsonResponse({ error: "method_not_allowed" }, 405);

  const auth = req.headers.get("Authorization");
  if (!auth || !auth.toLowerCase().startsWith("bearer ")) {
    return jsonResponse({ error: "missing_bearer" }, 401);
  }

  const url     = Deno.env.get("SUPABASE_URL")!;
  const anon    = Deno.env.get("SUPABASE_ANON_KEY")!;
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Verify the JWT by asking the auth server who it represents.
  const userClient = createClient(url, anon, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData?.user) {
    return jsonResponse({ error: "invalid_jwt", detail: userErr?.message ?? null }, 401);
  }
  const userId = userData.user.id;

  // Now privileged. From here on `admin` bypasses RLS — never echo back
  // anything from the request body, only the verified userId.
  const admin = createClient(url, service, { auth: { persistSession: false } });
  const wiped: string[] = [];
  const errors: Record<string, string> = {};

  for (const t of TABLES_TO_WIPE) {
    try {
      const { error } = await admin.from(t.name).delete().eq(t.col, userId);
      if (error) {
        // Missing-row / no-match is not an error from PostgREST DELETE,
        // but a missing table or RLS denial is. Record and continue.
        errors[`${t.name}.${t.col}`] = error.message;
      } else {
        wiped.push(`${t.name}.${t.col}`);
      }
    } catch (e) {
      errors[`${t.name}.${t.col}`] = (e as Error).message;
    }
  }

  // Last: delete the auth user. If this fails the public rows are
  // already gone, so the next retry will only need to delete the
  // auth.users row.
  const { error: authErr } = await admin.auth.admin.deleteUser(userId);
  if (authErr) {
    return jsonResponse(
      {
        deleted: false,
        user_id: userId,
        tables: wiped,
        errors,
        auth_error: authErr.message,
      },
      500,
    );
  }

  return jsonResponse({
    deleted: true,
    user_id: userId,
    tables: wiped,
    errors: Object.keys(errors).length ? errors : undefined,
  });
});
