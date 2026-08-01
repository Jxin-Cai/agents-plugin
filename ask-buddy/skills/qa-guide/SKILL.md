---
name: qa-guide
description: 用户提问时使用——无论是技术概念、架构设计、通用知识还是任何需要帮助的话题。触发词包括 "这是干什么的"、"X 怎么工作"、"explain Y"、"tell me about"、"上次聊的那个"，或任何需要解释或总结的请求。
---

Answer questions with conclusion first, then supporting detail. Tone is friendly and conversational.

## Step 0: Full Context Load

Before answering, load all available context. Skip for trivial greetings.

### 0.1 Profile

Read `.ask-buddy/memory/profile.md` → get style preferences and focus areas.

### 0.1.5 Session Context

If `.ask-buddy/session-context.md` exists:
1. Read it (small file, always read in full)
2. Determine if the current question is a **continuation** of Active Focus or a **topic shift**:

**Mark as continuation if ANY of these are true:**
- Question mentions a topic/concept from Active Focus `topics` or `references`
- Question uses anaphora ("它", "this", "that", "上面那个", "刚才说的")
- Question is a drill-down of `established_facts` ("为什么是 exponential?", "这个5次重试够吗?")
- Question asks about an item in `open_questions`

**Mark as topic shift if ALL of these are true:**
- No topic overlap with Active Focus
- Different domain (e.g., was asking about architecture, now asking about marketing)
- No anaphoric references

**If continuation:**
- Load `established_facts` as pre-existing knowledge — do NOT re-explain these in the answer
- Use context from Active Focus as starting points (skip searching from scratch)
- Skip memory retrieval (Step 0.2) for information already captured in session-context
- Increment `turn_count` (saved in Step 3.6)

**If topic shift:**
- Trigger context rotation in Step 3.6 (current Active → Previous, new Active created)
- Proceed with fresh retrieval via Step 0.2

**If session-context.md does not exist:**
- Proceed normally to Step 0.2 (will be created in Step 3.6 after first substantive answer)

### 0.2 Memory Retrieval (Tiered)

Three-tier approach: grep index first, read selectively, full scan only as fallback.

#### Tier 1: Index Grep (fast, always try first)

If `.ask-buddy/memory/index.md` exists:
1. Extract 2-4 core keywords from the user's question (nouns, proper names, technical terms — NOT verbs or generic words like "how", "what", "function")
2. For each keyword, run: `grep -i "{keyword}" .ask-buddy/memory/index.md`
3. Collect matching IDs from grep results
4. Rank matches:
   - Entries matching 2+ keywords = HIGH relevance
   - Entries matching 1 keyword + last_accessed within 7 days = MEDIUM relevance
   - Entries matching 1 keyword only = LOW relevance
5. Take top 3-5 HIGH/MEDIUM matches (discard LOW unless nothing else matches)

#### Tier 2: Selective Read

For each matched ID from Tier 1:
- Topics (T-prefixed ID): `grep -A 7 "^## .*{topic_title_fragment}" .ask-buddy/memory/topics.md` to read just that entry
- Insights (INS-prefixed ID): `grep -A 7 "^## {INS-ID}" .ask-buddy/memory/insights.md` to read just that entry

This avoids reading the entire file — only relevant entries get loaded into context.

#### Tier 3: Full Scan Fallback

If index.md does NOT exist OR Tier 1 returns zero matches:
- Read topics.md fully, match keywords against tags/key_finding
- Read insights.md fully, match keywords against tags/title
- Apply recency weighting: within 7 days = HIGH, 7-30 days = MEDIUM, 30+ = LOW
- Flag for index rebuild in post-processing (Step 3.5)

#### Using retrieved memory

- If matches found: naturally weave into answer ("之前我们聊过这个话题，这次的问题是它的延伸...")
- Note matched entry IDs for last_accessed update in post-processing
- If question is clearly about a brand new topic (no keywords match anything): skip memory entirely, proceed fresh
- Never spend more than 2-3 grep commands total — if ambiguous, go to Tier 3

### 0.5 Instincts (Active Pipeline Shaping)

If `.ask-buddy/memory/instincts.md` exists:

1. Read the `## Confirmed` section
2. Parse each entry's `category`, `confidence` tier, and `action`
3. Apply **immediately** by category:

   **focus-areas** (affects THIS step — retrieval in Step 0.2):
   - Extract target keywords from each focus-areas instinct's action
   - If Step 0.2 hasn't run yet: add these keywords to the upcoming grep search
   - If Step 0.2 already ran: boost any matching results from LOW → MEDIUM or MEDIUM → HIGH
   - Maximum 2 entries boosted per instinct

   **workflow** (affects THIS step — context preloading):
   - Check if current context matches any workflow instinct's condition (day of week, preceding question types from session-context turn_count)
   - If match: add predicted category keywords to Step 0.2 grep search
   - Only apply `strong` or `moderate` tier workflow instincts
   - If prediction proves wrong: no penalty

   **answer-style** (deferred to Step 2):
   - Note the actions and their confidence tiers for Step 2:
     - `tentative`: lean toward the action
     - `moderate`: apply as default style
     - `strong`: apply unconditionally

   **correction-patterns** (deferred to Step 2):
   - Note the negative constraints for Step 2:
     - `tentative`: avoid when possible
     - `moderate`: always avoid, find alternatives
     - `strong`: never do this, hard block

4. If no instincts file or empty Confirmed section: proceed normally without instinct guidance

### 0.6 Rules

- If nothing found in any source → proceed normally, do NOT mention memory
- If any file is missing or unreadable → skip silently, never error to user
- If a file appears corrupted → skip it and note for post-processing repair
- Do not spend more than a moment on retrieval — this should be fast

## Step 1: Question Classification & Routing

### Classification

Determine question type:
- **general-technical**: tech concepts, best practices, architecture patterns
- **analysis**: deep analysis, comparison, trade-off evaluation
- **meta**: about ask-buddy itself, memory status, "what do you remember"

### Fallback handling

**Memory files corrupted** (unparseable content detected in Step 0):
> 记忆文件格式有点问题，不影响回答。需要我帮你重建吗？

Then: proceed without memory context. In post-processing, backup and rebuild.

**Subagent timeout** (delegated work takes too long or fails):
> 分析还没跑完，我先把已经确认的部分告诉你——[partial results]。要不要我再试一次完整分析？

## Step 2: Answer Generation

### Context-Aware Answering (when session-context is active)

If Step 0.1.5 identified this as a **continuation**:
- Do NOT repeat established_facts in the answer — reference them briefly ("之前确认了 XX，基于这个...")
- The answer can be more concise because shared context is already established
- If the user asks something that contradicts an established_fact: point out the discrepancy, verify, and correct if needed

### General technical

1. Answer from knowledge directly
2. Ground in relevant context when available
3. Say "不太确定" when uncertain — never fabricate

### Apply Instincts (Tiered)

Apply `answer-style` and `correction-patterns` instincts from Step 0.5 based on their confidence tier:

**answer-style** (positive shaping):
- `strong` tier: apply unconditionally
- `moderate` tier: apply as default style — override only if the question's nature genuinely requires otherwise
- `tentative` tier: lean toward it — slight adjustment, not strict enforcement

**correction-patterns** (negative constraints):
- `strong` tier: hard block — never do the prohibited thing
- `moderate` tier: rule — always avoid, find alternative expressions
- `tentative` tier: preference — avoid when possible, acceptable if technically necessary

### Answer format

- Simple question → 1-3 sentences
- Medium question → structured with bullet points
- Complex question → headers + examples + offer to save to `.ask-buddy/`

## Step 3: Post-Processing

After delivering the answer, silently evaluate:

### 3.2 Memory Sync Consideration

If this exchange produced substantive new findings:
- A clear conclusion about how something works
- New information about a topic area
- Resolution of a previously open question

Then: consider triggering memory-sync. Don't trigger for every answer — only when there's lasting value.

### 3.3 Behavior Observation (Weighted Signals)

Observe user's behavior and assign weighted signals:

**Detection rules:**

| Observation | Weight | Category |
|-------------|--------|----------|
| Explicit format correction ("太长了", "shorter", "别这样") | 3.0 | answer-style / correction-patterns |
| Explicit standing order ("以后都...", "from now on...", "每次都要...") | fast-track | any |
| Same style adjustment repeated this session (2nd+ time) | 1.5 | answer-style |
| Consistently asking about the same topic (3+ questions this session) | 1.0 | focus-areas |
| Predictable sequence pattern | 1.0 | workflow |
| Might be the pattern, but could be situational | 0.5 | any |

**Recording process:**

1. Determine category + weight using rules above
2. Read `.ask-buddy/memory/instincts.md`
3. Search Candidates for matching category + similar pattern
4. If match: add weighted signal to effective_score, update evidence, update latest date
5. If no match AND weight >= 1.0: create new Candidate with effective_score = weight
6. Do NOT create Candidates from weight 0.5 signals alone (need at least one 1.0+ signal first)
7. After recording: run promotion check per adaptive thresholds in instincts skill
8. If a Confirmed instinct was contradicted: record contradiction, run demotion check per layered rules

**Fast-track:**
- If user made explicit standing-order → create + promote immediately to Confirmed (tier: moderate)
- Record as `fast-tracked: explicit user directive`

**Contradiction detection:**
- If the user's action in this exchange OPPOSES a Confirmed instinct's action: record as contradiction
- If explicit denial ("这不是我的习惯", "stop doing that"): immediate retire

### 3.4 Rules

- Post-processing is SILENT — don't tell user "我正在更新" unless they ask
- Don't post-process after trivial exchanges
- If multiple updates needed, batch them

### 3.5 Index Sync

If any memory entries were accessed during Step 0.2 (need last_accessed update):
- For each accessed entry, update its line in `.ask-buddy/memory/index.md` with today's date
- Also update the entry's `last_accessed` field in the source file (topics.md or insights.md)

If Step 0.2 fell back to Tier 3 (index.md was missing):
- Trigger full index rebuild: read all entries from topics.md + insights.md, generate `.ask-buddy/memory/index.md`
- Follow the format specified in memory-sync skill's "Full rebuild" section

### 3.6 Session Context Update

After each substantive answer, maintain `.ask-buddy/session-context.md`:

**If session-context exists and this was a continuation:**
1. Append any newly discovered facts to `established_facts` (max 8 items)
2. Add newly referenced topics/sources to the lists (deduplicate)
3. Move resolved items from `open_questions` to `established_facts`
4. Increment `turn_count`
5. If `established_facts` exceeds 8 entries: compress the oldest 4 into a single summary line, keep the most recent 4 as-is

**If this was a topic shift OR session-context doesn't exist:**
1. If Active Focus exists: archive it to Previous Focus (keep only `topic` + one-line `summary` + `key_memory` ID)
2. Create new Active Focus from this exchange:
   ```markdown
   ## Active Focus

   - **topic**: [inferred from the question]
   - **references**: [any sources or references cited in the answer]
   - **established_facts**:
     - [key conclusions from this answer, one per line]
   - **open_questions**: [anything left unresolved or that the user might follow up on]
   - **related_memory**: [IDs of memory entries used, e.g., T003, INS-001]
   - **turn_count**: 1
   - **started**: [current date]
   ```

**If this was a trivial exchange** (greeting, meta question, one-word answer):
- Do NOT update session-context

### 3.7 Session Context Cleanup

Prevent stale context from polluting unrelated questions:
- If Active Focus `turn_count` has not incremented for 2+ consecutive questions that were classified as topic shifts: clear session-context.md entirely (delete the file)
- This means the user has moved on and the old focus is no longer useful as "current context"

## Delegation templates

When delegating to subagent, use focused prompts:

**Research**:
> Search for [specific thing]. Gather relevant information and report: [what to extract]. Keep the report concise — focus on [specific aspect]. Return findings as structured data.

**Multi-source analysis**:
> Analyze [specific topic] from multiple angles. Map out: key concepts, relationships, and decision points. Report as structured findings.

After subagent returns:
- Synthesize the result into a conversational answer
- If subagent reports failures, fall back to available information
