---
name: memory-sync
description: 更新 Ask Buddy 的持久记忆文件。当对话产生实质性发现或结论、累计 10+ 次实质交流、用户切换话题或偏好变更时自动触发。也可通过 "记一下"、"save this"、"更新记忆"、"remember this"、"总结一下"、"summarize our chat"、"存个档"、"save progress" 手动触发。简单寒暄或单问单答不触发。
---

Update memory files in `.ask-buddy/memory/` based on conversation content.

## Files

| File | Content | Format |
|------|---------|--------|
| `profile.md` | User role, preferences, focus areas | Structured fields |
| `topics.md` | Topics discussed with key findings | Structured entries with tags |
| `insights.md` | Cross-topic insights worth long-term retention | Structured entries with evidence |
| `instincts.md` | Observed user behavior patterns | Three-section structure (managed by instincts skill) |

## When to auto-trigger

**Memory update** (after substantive conclusions):
- A topic was discussed in depth with clear conclusions
- User expressed new preferences or corrected understanding
- Discovered a cross-topic connection or insight

**Context summary** (proactive checkpoint):
- Conversation has had 10+ substantive Q&A exchanges
- User is pivoting to a completely different topic
- You notice you're starting to lose track of earlier details

Do NOT update after every message. Only when there's substantive new information.

## Format validation

Before any write operation:

1. Read the target file
2. Check the content can be parsed as expected structure (H2 headers for entries, bullet fields)
3. If valid: proceed with update
4. If corrupt or unparseable:
   - Create backup at `.ask-buddy/memory/_backup/{filename}.md`
   - Recreate file with empty template (see templates below)
   - Inform user casually: "记忆文件格式有点问题，我帮你重建了一份。之前的内容备份在 _backup 里。"
5. If file doesn't exist: create with empty template, no error

## Update rules

### topics.md — append new entry

```markdown
## YYYY-MM-DD: [Topic title]
- **tags**: [keyword1, keyword2, keyword3]
- **key_finding**: [one-line conclusion, max 100 chars]
- **related**: [references, sources, or other topic titles]
- **status**: resolved | open | needs-follow-up
- **confidence**: high
- **last_accessed**: YYYY-MM-DD
```

Rules:
- Each entry is an H2 with date prefix and descriptive title
- `tags`: 3-5 lowercase keywords for retrieval matching
- `key_finding`: one sentence capturing the core conclusion
- `related`: concrete references or related topic titles
- `status`: current resolution state
- `confidence`: starts as `high` for new entries
- `last_accessed`: set to today on creation; updated by qa-guide on retrieval hits
- Keep each entry to 6 lines max
- If file exceeds 50 entries, compress oldest fading entries (see decay section)

### insights.md — append or update

```markdown
## INS-NNN: [Insight title]
- **date**: YYYY-MM-DD
- **context**: [how this insight was derived]
- **tags**: [keyword1, keyword2]
- **evidence**: [topic titles or references that support this]
- **confidence**: high | medium
- **last_accessed**: YYYY-MM-DD
```

Rules:
- Sequential ID (INS-001, INS-002...) for cross-referencing
- Only add genuinely cross-topic, reusable observations
- `evidence`: at least one pointer to topics that supports the insight
- Before adding: check existing insights for duplicates or subsumptions
- If new insight subsumes an existing one: update the existing entry rather than adding

### instincts.md — managed by instincts skill

Do NOT directly modify instincts.md from memory-sync. Only the instincts skill manages this file. Memory-sync's role is limited to:
- Creating the empty template if missing
- Backing up if corrupted
- Including in format validation checks

### profile.md — update fields

Only modify when user explicitly corrects or when progressive modeling detects confirmed patterns.

## Index Maintenance

After ANY write to topics.md or insights.md, synchronize `.ask-buddy/memory/index.md`.

### On append (new entry)

1. Construct a single index line from the entry you just wrote:
   - Topics: `T{seq} | {tags as csv} | {key_finding first 20 chars} | {status} | {last_accessed}`
   - Insights: `{INS-ID} | {tags as csv} | {title first 20 chars} | {confidence} | {last_accessed}`
2. Append this line to the corresponding section in index.md (after the FORMAT comment)

### On update (last_accessed, status, confidence change)

1. Use Bash: `grep "^{ID} |" .ask-buddy/memory/index.md` to locate the line
2. Replace that line with updated field values

### On compression (decay merge)

1. Remove the compressed entries' index lines
2. Add one new line for the compressed summary entry

### Full rebuild (index missing or corrupted)

If index.md is missing when you need to update it:
1. Read topics.md — for each H2 entry, generate one index line
2. Read insights.md — for each H2 entry, generate one index line
3. Write complete index.md from template + all generated lines
4. Do this at most once per session

### ID scheme for topics

Topics don't have explicit IDs in the current format. Use sequential `T{NNN}` based on order of appearance in topics.md (first entry = T001, second = T002...). On full rebuild, re-number sequentially.

## Progressive User Modeling

Observe interaction patterns to calibrate profile.md:

**Signals to watch for**:
- User consistently asks for more/less detail → adjust Style preference
- User asks about new areas/topics → add to Focus
- User corrects your explanation level → adjust Notes

**How to update progressively**:
- Don't update after a single signal — wait for a pattern (2-3 consistent signals)
- When updating, note the evidence: `(observed: user asked for shorter answers 3 times)`
- Keep profile.md concise — max 10 lines of structured fields
- When a pattern is strong enough (3+ signals): also log as a signal for the instincts system

## Memory decay

On each memory-sync trigger, run a quick decay check:

1. Scan topics.md and insights.md for `last_accessed` fields
2. Entries not accessed in 30+ days: mark `confidence: fading`
3. Entries not accessed in 60+ days AND already `fading`: eligible for compression
4. **Compression rule**: If 3+ related fading entries share overlapping tags, merge them into one summary entry:
   ```markdown
   ## YYYY-MM-DD: [Compressed] Topics about [shared theme]
   - **tags**: [union of tags from merged entries]
   - **key_finding**: [brief summary of the merged findings]
   - **related**: [union of related references]
   - **status**: archived
   - **confidence**: archived
   - **last_accessed**: YYYY-MM-DD
   ```
5. Delete the original entries after compression
6. Maximum one compression pass per sync (don't spend too long on this)

## Communication style

When auto-triggered for context summary, be casual:
> 聊了不少了，我先存个档——把今天的关键发现记一下，免得后面忘了。

When manually triggered:
> 好的，总结一下我们今天聊的...

Show a brief summary (3-5 bullet points max) of what you're saving, then confirm: "记住了。"

## Empty templates

### topics.md
```markdown
# Topics

> 讨论过的话题与关键发现（按时间倒序）
```

### insights.md
```markdown
# Insights

> 跨话题的可复用洞察
```

### instincts.md
```markdown
# Instincts

> 观察到的用户行为模式

## Confirmed

## Candidates

## Retired
```

## Session Context Integration

When memory-sync triggers (auto or manual):
1. Check if `.ask-buddy/session-context.md` exists
2. If Active Focus has `turn_count >= 3` and contains substantial `established_facts`:
   - These facts likely deserve a topics.md entry if they haven't been saved yet
   - Cross-reference against existing topics.md entries to avoid duplication
   - If genuinely new: save as a new topic entry (date = Active Focus `started` date)
3. Do NOT delete session-context.md during memory-sync — it serves the current session
4. Do NOT save session-context content that is trivial or too granular for long-term memory

## Rules

- Don't summarize trivial exchanges
- Don't duplicate what's already in memory — check first
- Keep entries concise
- Never interrupt an active problem-solving flow — wait for a natural pause
- Always validate format before writing
- Backup before rebuild on corruption
- Run decay check at most once per session (not every sync)
