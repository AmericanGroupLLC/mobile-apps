// Thin wrapper around AWS Rekognition CompareFaces over the REST/JSON
// endpoint. We avoid the AWS SDK to keep the Deno bundle small.
//
// The client signs an SigV4 request manually. For tests, callers can
// replace the `awsFetch` symbol via dependency injection.

interface AwsCreds {
  region: string;
  accessKey: string;
  secretKey: string;
}

const ENCODER = new TextEncoder();

export async function rekognitionCompareFaces(
  source: Uint8Array,
  target: Uint8Array,
  creds: AwsCreds,
  fetcher: typeof fetch = fetch,
): Promise<number> {
  const body = JSON.stringify({
    SourceImage: { Bytes: u8ToBase64(source) },
    TargetImage: { Bytes: u8ToBase64(target) },
    SimilarityThreshold: 80, // we re-threshold to 90 in index.ts
  });

  const url = `https://rekognition.${creds.region}.amazonaws.com/`;
  const headers = await sigv4Headers({
    method: "POST",
    url,
    body,
    region: creds.region,
    service: "rekognition",
    accessKey: creds.accessKey,
    secretKey: creds.secretKey,
    target: "RekognitionService.CompareFaces",
  });

  const resp = await fetcher(url, { method: "POST", headers, body });
  if (!resp.ok) {
    throw new Error(`rekognition_${resp.status}`);
  }
  const json = await resp.json();
  const matches = Array.isArray(json.FaceMatches) ? json.FaceMatches : [];
  if (matches.length === 0) return 0;
  return Math.round(Number(matches[0].Similarity) || 0);
}

// ──────────────────────────────────────────────────────────────────────
// SigV4 (minimal)

interface SigParams {
  method: string;
  url: string;
  body: string;
  region: string;
  service: string;
  accessKey: string;
  secretKey: string;
  target: string;
}

async function sigv4Headers(p: SigParams): Promise<Record<string, string>> {
  const u = new URL(p.url);
  const now = new Date();
  const amzDate = isoBasic(now);
  const datestamp = amzDate.slice(0, 8);

  const canonicalHeaders =
    `content-type:application/x-amz-json-1.1\nhost:${u.host}\nx-amz-date:${amzDate}\nx-amz-target:${p.target}\n`;
  const signedHeaders = "content-type;host;x-amz-date;x-amz-target";

  const payloadHash = await sha256Hex(p.body);
  const canonicalRequest =
    `${p.method}\n${u.pathname || "/"}\n\n${canonicalHeaders}\n${signedHeaders}\n${payloadHash}`;

  const credentialScope = `${datestamp}/${p.region}/${p.service}/aws4_request`;
  const stringToSign =
    `AWS4-HMAC-SHA256\n${amzDate}\n${credentialScope}\n${await sha256Hex(canonicalRequest)}`;

  const kDate    = await hmacRaw(ENCODER.encode("AWS4" + p.secretKey), datestamp);
  const kRegion  = await hmacRaw(kDate, p.region);
  const kService = await hmacRaw(kRegion, p.service);
  const kSigning = await hmacRaw(kService, "aws4_request");
  const signature = bytesToHex(await hmacRaw(kSigning, stringToSign));

  return {
    "Content-Type": "application/x-amz-json-1.1",
    "X-Amz-Date":   amzDate,
    "X-Amz-Target": p.target,
    "Authorization":
      `AWS4-HMAC-SHA256 Credential=${p.accessKey}/${credentialScope},` +
      `SignedHeaders=${signedHeaders},Signature=${signature}`,
  };
}

function isoBasic(d: Date): string {
  return d.toISOString().replace(/[:-]|\.\d{3}/g, "");
}

async function sha256Hex(s: string): Promise<string> {
  const h = await crypto.subtle.digest("SHA-256", ENCODER.encode(s));
  return bytesToHex(new Uint8Array(h));
}

async function hmacRaw(key: Uint8Array, data: string): Promise<Uint8Array> {
  const k = await crypto.subtle.importKey(
    "raw", key, { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", k, ENCODER.encode(data));
  return new Uint8Array(sig);
}

function bytesToHex(b: Uint8Array): string {
  return Array.from(b).map(x => x.toString(16).padStart(2, "0")).join("");
}

function u8ToBase64(b: Uint8Array): string {
  let s = "";
  for (let i = 0; i < b.byteLength; i++) s += String.fromCharCode(b[i]);
  return btoa(s);
}
