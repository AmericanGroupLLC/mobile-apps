// Pure logic for fuzz-location. Mirrors the client-side LocationFuzzer.
// The client truncation is canonical; this server-side function is the
// defence-in-depth path.

export interface FuzzedLocation {
  zip_prefix3: string | null;
  county_fips: string | null;
  state_code:  string | null;
}

export async function fuzz(
  supabase: any, lat: number, lon: number,
): Promise<FuzzedLocation> {
  // The client-side fuzzer turns lat/lon into ZIP-3 directly via a baked-in
  // ZIP-prefix polygon table. Server-side, we only resolve county +
  // state — clients always also send their own ZIP-3 for completeness.
  const { data, error } = await supabase.rpc("nearest_county", { lat, lon });
  if (error || !data || data.length === 0) {
    return { zip_prefix3: null, county_fips: null, state_code: null };
  }
  const row = Array.isArray(data) ? data[0] : data;
  return {
    zip_prefix3: null,
    county_fips: String(row.fips ?? "").slice(0, 5) || null,
    state_code:  String(row.state_code ?? "").slice(0, 2) || null,
  };
}

// Pure helper so the unit test runs without a database.
export function truncateZip(zip: string | null | undefined): string | null {
  if (!zip) return null;
  const s = String(zip).replace(/[^0-9]/g, "");
  return s.length >= 3 ? s.slice(0, 3) : null;
}
