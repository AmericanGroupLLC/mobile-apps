// Pure-logic tests for the fuzzer. Run via:
//   deno test --allow-env --allow-net --no-check _test.ts

import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { truncateZip, fuzz } from "./fuzz.ts";

Deno.test("truncateZip pads exactly 3 chars", () => {
  assertEquals(truncateZip("94025"), "940");
  assertEquals(truncateZip("94025-1234"), "940");
  assertEquals(truncateZip(null), null);
  assertEquals(truncateZip(""), null);
  assertEquals(truncateZip("12"), null);                 // too short
});

Deno.test("fuzz returns null shape when RPC errors", async () => {
  const fakeSupabase = {
    rpc: async () => ({ data: null, error: new Error("boom") }),
  };
  const result = await fuzz(fakeSupabase as any, 37.42, -122.16);
  assert(result.zip_prefix3 === null);
  assert(result.county_fips === null);
  assert(result.state_code  === null);
});

Deno.test("fuzz never returns lat/lon-shaped fields", async () => {
  const fakeSupabase = {
    rpc: async () => ({ data: [{ fips: "06085", state_code: "CA" }], error: null }),
  };
  const result = await fuzz(fakeSupabase as any, 37.42, -122.16);
  assertEquals(result.county_fips, "06085");
  assertEquals(result.state_code,  "CA");
  assert(!("lat" in result));
  assert(!("lon" in result));
});
