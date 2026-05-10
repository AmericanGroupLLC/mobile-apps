// Tests for the pure-logic prompt builder. Run via:
//   deno test --allow-env --allow-net --no-check _test.ts

import {
  assertStringIncludes,
  assert,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { buildReplyPrompt, fallbackSuggestions } from "./prompt.ts";

const A = { displayName: "Sara",   intent: "dating",  vibeTags: ["coffee", "books"] };
const B = { displayName: "Maya",   intent: "serious", vibeTags: ["hiking"] };

Deno.test("system prompt contains the strict-JSON contract", () => {
  const { system } = buildReplyPrompt({ tone: "slow", profiles: [A, B], messages: [] });
  assertStringIncludes(system, '{\"casual\"');
  assertStringIncludes(system, "private location");
});

Deno.test("user section includes both profile names and intents", () => {
  const { user } = buildReplyPrompt({ tone: "slow", profiles: [A, B], messages: [] });
  assertStringIncludes(user, "Sara");
  assertStringIncludes(user, "Maya");
  assertStringIncludes(user, "dating");
  assertStringIncludes(user, "serious");
});

Deno.test("messages render in chronological order (oldest first)", () => {
  const { user } = buildReplyPrompt({
    tone: "slow",
    profiles: [A, B],
    messages: [
      { authorId: "x", text: "hi",  createdAt: "2026-05-01T10:00:00Z" },
      { authorId: "y", text: "hey", createdAt: "2026-05-01T10:01:00Z" },
    ],
  });
  const iHi  = user.indexOf("hi");
  const iHey = user.indexOf("hey");
  assert(iHi >= 0 && iHey > iHi, "hi should appear before hey");
});

Deno.test("meetup_ready tone biases toward public-place suggestion", () => {
  const { system } = buildReplyPrompt({ tone: "meetup_ready", profiles: [A, B], messages: [] });
  assertStringIncludes(system, "public-place");
});

Deno.test("empty message set yields opener suggestion clause", () => {
  const { user } = buildReplyPrompt({ tone: "slow", profiles: [A, B], messages: [] });
  assertStringIncludes(user, "no messages yet");
});

Deno.test("fallbackSuggestions returns three non-empty strings", () => {
  const f = fallbackSuggestions();
  assert(f.casual.length > 0);
  assert(f.context.length > 0);
  assert(f.playful.length > 0);
});
