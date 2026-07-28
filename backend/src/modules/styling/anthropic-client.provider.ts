import Anthropic from '@anthropic-ai/sdk';

// Same shape as ../auth/firebase-admin.provider.ts: lazily created from an
// env var the first time it's actually used, so importing this file never
// has side effects on its own. ANTHROPIC_API_KEY doesn't exist in this
// environment yet (see docs/ROADMAP.md Phase 8) — StylingService checks
// isAnthropicConfigured() before ever calling getAnthropicClient().
let client: Anthropic | undefined;

export function isAnthropicConfigured(): boolean {
  return Boolean(process.env.ANTHROPIC_API_KEY);
}

export function getAnthropicClient(): Anthropic {
  if (!client) {
    client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
  }
  return client;
}
