import { env } from '../config/env';
import { prisma } from '../db';

export interface Knowledge {
  id: string;
  title: string;
  content: string;
  subject?: string | null;
}

export interface LlmProvider {
  complete(system: string, user: string): Promise<string>;
}

// Unicode-aware tokenizer so Devanagari (Nepali) works as well as English.
export function tokenize(text: string): string[] {
  return (text.toLowerCase().match(/[\p{L}\p{M}\p{N}]+/gu) ?? []).filter((t) => t.length > 1);
}

export function rank(question: string, entries: Knowledge[], limit = 4): Knowledge[] {
  const q = new Set(tokenize(question));
  return entries
    .map((e) => {
      const title = new Set(tokenize(e.title));
      const body = new Set(tokenize(e.content));
      let score = 0;
      q.forEach((t) => {
        if (title.has(t)) score += 3;
        if (body.has(t)) score += 1;
      });
      return { e, score };
    })
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map((x) => x.e);
}

/** Calls any OpenAI-compatible chat completions endpoint. */
export class OpenAiCompatible implements LlmProvider {
  async complete(system: string, user: string): Promise<string> {
    const res = await fetch(`${env.ai.baseUrl.replace(/\/$/, '')}/chat/completions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + env.ai.apiKey },
      body: JSON.stringify({
        model: env.ai.model,
        temperature: 0.3,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user },
        ],
      }),
      signal: AbortSignal.timeout(30_000),
    });
    if (!res.ok) throw new Error(`LLM request failed: ${res.status}`);
    const data = (await res.json()) as { choices?: { message?: { content?: string } }[] };
    return data.choices?.[0]?.message?.content?.trim() ?? '';
  }
}

let llm: LlmProvider | undefined = env.ai.apiKey ? new OpenAiCompatible() : undefined;
export const setLlm = (p: LlmProvider | undefined) => {
  llm = p;
};

export async function answer(question: string): Promise<{ answer: string; sources: { id: string; title: string }[] }> {
  const entries = await prisma.knowledgeEntry.findMany({ take: 2000 });
  const top = rank(question, entries);
  const sources = top.map((e) => ({ id: e.id, title: e.title }));

  if (!llm) {
    const text = top.length
      ? top.map((e) => `${e.title}\n${e.content}`).join('\n\n')
      : 'I do not have notes on this yet. Please ask your teacher or try rephrasing. / यस विषयमा मसँग अहिले नोट छैन।';
    return { answer: text, sources };
  }

  const context = top.length
    ? top.map((e, i) => `[${i + 1}] ${e.title}\n${e.content}`).join('\n\n')
    : '(no matching course notes)';
  const text = await llm.complete(
    env.ai.systemPrompt,
    `Course notes:\n${context}\n\nStudent question:\n${question}`,
  );
  return { answer: text, sources };
}
