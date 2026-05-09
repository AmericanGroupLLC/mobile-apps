// Drift Edge Function: reply-suggest
// Inputs: { conversation_id }
// Outputs: { casual: string, context: string, playful: string, tone: string }
//
// Reads the conversation, the two profiles, and the last 5 messages from
// Supabase using the caller's JWT (so RLS still gates access). Builds a
// prompt via `buildReplyPrompt` and calls the configured LLM provider. The
// LLM key never leaves the function; the client only sends `conversation_id`.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import { buildReplyPrompt, fallbackSuggestions } from "./prompt.ts";

interface ReplySuggestion {
  casual: string;
  context: string;
  playful: string;
  tone: string;
}

interface RequestBody {
  conversation_id: string;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

async function loadContext(supabase: SupabaseClient, conversationId: string) {
  const { data: conv, error: convErr } = await supabase
    .from("conversations")
    .select("id, profile_a_id, profile_b_id, tone")
    .eq("id", conversationId)
    .single();
  if (convErr || !conv) throw new Error("conversation_not_found");

  const { data: profiles, error: pErr } = await supabase
    .from("profiles")
    .select("id, display_name, intent, vibe_tags")
    .in("id", [conv.profile_a_id, conv.profile_b_id]);
  if (pErr || !profiles || profiles.length !== 2)
    throw new Error("profiles_missing");

  const { data: messages, error: mErr } = await supabase
    .from("messages")
    .select("author_id, text, created_at")
    .eq("conversation_id", conversationId)
    .order("created_at", { ascending: false })
    .limit(5);
  if (mErr) throw new Error("messages_load_failed");

  return { conv, profiles, messages: (messages || []).reverse() };
}

async function callLlm(prompt: { system: string; user: string }): Promise<ReplySuggestion> {
  const apiKey = Deno.env.get("LLM_API_KEY");
  const provider = Deno.env.get("LLM_PROVIDER") || "openai";
  if (!apiKey) {
    return { ...fallbackSuggestions(), tone: "slow" };
  }

  if (provider === "openai") {
    const resp = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: Deno.env.get("LLM_MODEL") || "gpt-4o-mini",
        temperature: 0.8,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: prompt.system },
          { role: "user",   content: prompt.user },
        ],
      }),
    });
    if (!resp.ok) throw new Error(`llm_${resp.status}`);
    const json = await resp.json();
    const text = json.choices?.[0]?.message?.content || "{}";
    return JSON.parse(text);
  }

  // anthropic / others can be added here.
  throw new Error(`unsupported_provider_${provider}`);
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const auth = req.headers.get("Authorization");
  if (!auth) return new Response("missing auth", { status: 401, headers: corsHeaders });

  const url = Deno.env.get("SUPABASE_URL")!;
  const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
  const supabase = createClient(url, anon, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false },
  });

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return new Response("bad request", { status: 400, headers: corsHeaders });
  }
  if (!body?.conversation_id) {
    return new Response("conversation_id required", { status: 400, headers: corsHeaders });
  }

  try {
    const { conv, profiles, messages } = await loadContext(supabase, body.conversation_id);
    const prompt = buildReplyPrompt({
      tone: conv.tone,
      profiles: profiles.map((p: any) => ({
        displayName: p.display_name,
        intent: p.intent,
        vibeTags: p.vibe_tags ?? [],
      })),
      messages: messages.map((m: any) => ({
        authorId: m.author_id,
        text: m.text,
        createdAt: m.created_at,
      })),
    });
    const suggestions = await callLlm(prompt);
    return new Response(
      JSON.stringify({
        casual:  String(suggestions.casual || ""),
        context: String(suggestions.context || ""),
        playful: String(suggestions.playful || ""),
        tone:    conv.tone,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e: any) {
    console.error("reply-suggest error:", e?.message);
    return new Response(JSON.stringify({ ...fallbackSuggestions(), tone: "slow" }), {
      status: 200,                  // graceful client fallback
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
