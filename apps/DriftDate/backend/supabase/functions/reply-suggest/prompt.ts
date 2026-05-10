// Pure-logic prompt construction for the reply-suggest Edge Function.
// This is the TS port of `ReplyPromptBuilder.swift` / `ReplyPromptBuilder.kt`.
// Keep the three implementations in sync.

export interface ProfileLite {
  displayName: string;
  intent: string;
  vibeTags: string[];
}

export interface MessageLite {
  authorId: string;
  text: string;
  createdAt: string; // ISO8601
}

export interface ReplyPromptInput {
  tone: string;
  profiles: ProfileLite[];   // exactly 2, in canonical order (a, b)
  messages: MessageLite[];   // last 5 in chronological order (oldest first)
}

export interface BuiltPrompt {
  system: string;
  user: string;
}

export function buildReplyPrompt(input: ReplyPromptInput): BuiltPrompt {
  const [a, b] = input.profiles;
  const toneClause = toneSpecificClause(input.tone);

  const system =
    "You write three short reply suggestions for a Drift dating app chat. " +
    "Return strict JSON: {\"casual\": ..., \"context\": ..., \"playful\": ...}. " +
    "Each suggestion is one sentence, ≤ 140 characters, no emoji unless playful, " +
    "and never asks for private location. " +
    toneClause;

  const profilesSection =
    `Person A: ${a.displayName} (intent: ${a.intent}, vibes: ${a.vibeTags.join(", ") || "—"})\n` +
    `Person B: ${b.displayName} (intent: ${b.intent}, vibes: ${b.vibeTags.join(", ") || "—"})`;

  const messagesSection = input.messages.length === 0
    ? "(no messages yet — these are opener suggestions)"
    : input.messages
        .map(m => `${shortAuthorLabel(m.authorId, a, b)}: ${m.text}`)
        .join("\n");

  const user = `${profilesSection}\n\nLast messages (oldest → newest):\n${messagesSection}`;

  return { system, user };
}

function shortAuthorLabel(id: string, a: ProfileLite, b: ProfileLite): string {
  // Profiles don't carry id in this lite shape; we let the caller pass
  // matching ids through as part of the message stream. Here we just
  // alias to A/B by stable comparison against display name.
  if (id === (a as any).id) return "A";
  if (id === (b as any).id) return "B";
  return "?";
}

function toneSpecificClause(tone: string): string {
  switch (tone) {
    case "energetic":   return "The conversation has good energy — match it. Light playful escalation is welcome.";
    case "deep":        return "The conversation is thoughtful and longer-form. Match the depth; ask one open follow-up.";
    case "meetup_ready": return "Both parties seem meetup-ready. Suggest a public-place hangout (coffee, walk, public event) — never request a private location share.";
    case "slow":
    default:            return "The conversation is slow. Keep suggestions light and easy to answer.";
  }
}

export function fallbackSuggestions(): { casual: string; context: string; playful: string } {
  return {
    casual:  "Hey — how's your week going?",
    context: "What's been on your mind lately?",
    playful: "Pick a fight: best pizza topping?",
  };
}
