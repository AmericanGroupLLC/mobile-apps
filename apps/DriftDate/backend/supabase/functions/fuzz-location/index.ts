// Drift Edge Function: fuzz-location
// Inputs: { lat: number, lon: number }
// Outputs: { zip_prefix3: string|null, county_fips: string|null, state_code: string|null }
//
// Defence-in-depth fuzzer. The client is the canonical fuzzer (truncates
// before sending anything to the network). This function exists so that
// even if a client is buggy, the lat/lon never reaches storage. We
// truncate, look up the county centroid, and return the fuzzed result.
// We DO NOT log the incoming lat/lon, and we don't write them anywhere.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import { fuzz } from "./fuzz.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const auth = req.headers.get("Authorization");
  if (!auth) return new Response("missing auth", { status: 401, headers: corsHeaders });

  const body = await req.json().catch(() => null);
  const lat = Number(body?.lat);
  const lon = Number(body?.lon);
  if (!Number.isFinite(lat) || !Number.isFinite(lon) ||
      lat < -90 || lat > 90 || lon < -180 || lon > 180) {
    return new Response(JSON.stringify({ zip_prefix3: null, county_fips: null, state_code: null }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const url  = Deno.env.get("SUPABASE_URL")!;
  const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
  const supabase = createClient(url, anon, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false },
  });

  // PostGIS-backed nearest county lookup. This runs on the server with
  // service-role permission via the helper RPC. The lat/lon stays in
  // function memory and is never persisted.
  const fuzzed = await fuzz(supabase, lat, lon);
  return new Response(JSON.stringify(fuzzed), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
