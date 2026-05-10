// Tests for the AWS helper. We don't call real Rekognition — we inject a
// fake fetcher that returns canned JSON.
//   deno test --allow-env --allow-net --no-check _test.ts

import {
  assertEquals,
  assert,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { rekognitionCompareFaces } from "./aws.ts";

const fakeImage = new Uint8Array([0x89, 0x50, 0x4E, 0x47]);

function fakeFetcher(similarity: number): typeof fetch {
  return (async (_input, init) => {
    // Sanity-check the request body shape.
    const body = init?.body ? JSON.parse(String(init.body)) : {};
    assert(body.SourceImage?.Bytes, "missing SourceImage.Bytes");
    assert(body.TargetImage?.Bytes, "missing TargetImage.Bytes");
    return new Response(
      JSON.stringify({ FaceMatches: [{ Similarity: similarity }] }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  }) as unknown as typeof fetch;
}

Deno.test("returns rounded similarity for a successful match", async () => {
  const sim = await rekognitionCompareFaces(fakeImage, fakeImage, {
    region: "us-east-1", accessKey: "AKIA", secretKey: "secret",
  }, fakeFetcher(94.6));
  assertEquals(sim, 95);
});

Deno.test("returns 0 when no faces match", async () => {
  const noMatch = (async () =>
    new Response(JSON.stringify({ FaceMatches: [] }), { status: 200 })) as unknown as typeof fetch;
  const sim = await rekognitionCompareFaces(fakeImage, fakeImage, {
    region: "us-east-1", accessKey: "AKIA", secretKey: "secret",
  }, noMatch);
  assertEquals(sim, 0);
});

Deno.test("non-200 throws", async () => {
  const fail = (async () =>
    new Response("nope", { status: 500 })) as unknown as typeof fetch;
  let threw = false;
  try {
    await rekognitionCompareFaces(fakeImage, fakeImage, {
      region: "us-east-1", accessKey: "AKIA", secretKey: "secret",
    }, fail);
  } catch { threw = true; }
  assert(threw);
});
