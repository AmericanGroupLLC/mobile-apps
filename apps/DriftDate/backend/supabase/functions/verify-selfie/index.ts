// Drift Edge Function: verify-selfie
// Inputs: { selfie_image_id, comparison_photo_id }
// Outputs: { verified: boolean, similarity: number }
//
// Calls AWS Rekognition CompareFaces. On verified=true, sets
// `profiles.verified_at = now()`. The selfie image bytes are deleted from
// the `selfies/` storage bucket immediately after the call returns. Only the
// boolean result is persisted.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import { rekognitionCompareFaces } from "./aws.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const SIMILARITY_THRESHOLD = 90;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const auth = req.headers.get("Authorization");
  if (!auth) return new Response("missing auth", { status: 401, headers: corsHeaders });

  const url  = Deno.env.get("SUPABASE_URL")!;
  const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
  const supabase = createClient(url, anon, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false },
  });

  const body = await req.json().catch(() => null);
  if (!body?.selfie_image_id || !body?.comparison_photo_id) {
    return new Response("selfie_image_id and comparison_photo_id required",
      { status: 400, headers: corsHeaders });
  }

  // Identify the caller from JWT (RLS already enforces the rest).
  const { data: u } = await supabase.auth.getUser();
  const userId = u.user?.id;
  if (!userId) return new Response("unauth", { status: 401, headers: corsHeaders });

  try {
    const selfiePath     = `selfies/${userId}/${body.selfie_image_id}`;
    const comparisonPath = `photos/${userId}/${body.comparison_photo_id}`;

    const [selfieBytes, comparisonBytes] = await Promise.all([
      downloadStorage(supabase, "selfies", selfiePath.replace(/^selfies\//, "")),
      downloadStorage(supabase, "photos",  comparisonPath.replace(/^photos\//,  "")),
    ]);

    const similarity = await rekognitionCompareFaces(selfieBytes, comparisonBytes, {
      region:    Deno.env.get("AWS_REGION") || "us-east-1",
      accessKey: Deno.env.get("AWS_ACCESS_KEY_ID")!,
      secretKey: Deno.env.get("AWS_SECRET_ACCESS_KEY")!,
    });

    const verified = similarity >= SIMILARITY_THRESHOLD;

    if (verified) {
      await supabase
        .from("profiles")
        .update({ verified_at: new Date().toISOString() })
        .eq("id", userId);
    }

    // Delete selfie bytes — we never persist them past this call.
    await supabase.storage.from("selfies").remove([selfiePath.replace(/^selfies\//, "")])
      .catch((e: unknown) => console.warn("selfie cleanup failed:", e));

    return new Response(JSON.stringify({ verified, similarity }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e: any) {
    console.error("verify-selfie error:", e?.message);
    return new Response(JSON.stringify({ verified: false, error: "verification_failed" }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

async function downloadStorage(
  supabase: any, bucket: string, path: string,
): Promise<Uint8Array> {
  const { data, error } = await supabase.storage.from(bucket).download(path);
  if (error || !data) throw new Error(`download_failed_${bucket}_${path}`);
  return new Uint8Array(await data.arrayBuffer());
}
