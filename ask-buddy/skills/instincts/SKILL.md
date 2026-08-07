---
name: instincts
description: 用户行为模式识别系统。当 qa-guide 第3步检测到重复行为模式时自动触发。也可通过 "我的习惯"、"my patterns"、"你觉得我喜欢什么"、"instinct check"、"行为分析"、"你了解我吗"、"what do you know about me" 手动触发。
---

Observe user behavior patterns, accumulate evidence, and use confirmed patterns to proactively optimize answers.

## Core principles

- **Observe quietly** — collect candidates without interrupting Q&A flow
- **Confirm before influence** — inferred patterns never shape answers until the user approves them
- **Fail gracefully** — wrong predictions get retired immediately, no harm done
- **Respect privacy** — only record work-relevant patterns, never personal details

## File location

`.ask-buddy/memory/instincts.md`

## Operations

### Record Signal (Weighted)

Called by qa-guide Step 3 when a behavior pattern is observed.

Input: category, signal description, date, weight

#### Signal Weights

| Signal type | Weight | Example |
|-------------|--------|---------|
| Explicit correction | 3.0 | "太长了", "shorter please", "不要这样", "以后都..." |
| Repeated same-session | 1.5 | Same pattern observed 2+ times in one conversation |
| Cross-session consistent | 1.0 | Standard observation across different sessions |
| Weak/ambiguous | 0.5 | Could be the pattern, but could also be situational |

#### Process

1. Read instincts.md
2. Search **Candidates** section for matching category + similar signal
3. If match found:
   - Add weighted signal to `effective_score` (not raw count increment)
   - Update "最近" date
   - Append new evidence point
4. If no match AND weight >= 1.0:
   - Create new Candidate entry with effective_score = weight
   - Do NOT create candidates from weight 0.5 signals alone
5. After recording: check promotion criteria

#### Fast-track rule

If the user makes an explicit standing-order statement ("以后都...", "from now on always...", "never ... again", "每次都要..."):
- Create the instinct AND promote immediately to Confirmed with tier `moderate`
- Set `fast-tracked: explicit user directive` in the entry
- Do NOT require score accumulation for clear mandates

### Promote (Adaptive Thresholds + Approval)

After each signal recording, check promotion eligibility:

| Condition | Ready for review? | Rationale |
|-----------|-----------|-----------|
| effective_score >= 5.0 AND contradictions == 0 | YES | Standard path |
| effective_score >= 3.0 AND time span > 14 days AND contradictions == 0 | YES | Slow-burn consistent pattern |
| effective_score >= 8.0 AND contradictions <= 1 | YES | Overwhelming evidence, minor noise tolerated |
| Fast-track (explicit user directive) | Promote immediately | Clear user mandate |

When an inferred Candidate reaches a threshold:
- Add `ready_for_review: true`
- Wait for a natural pause or a manual pattern review
- Ask one concise confirmation question; do not apply the pattern yet

On user-approved promotion:
- Move entry from Candidates to Confirmed
- Assign confidence tier (see below)
- Assign `active_influence` based on category

### Confidence Tiers

Confirmed instincts have a confidence tier that affects application strength:

| Tier | Criteria | Application |
|------|----------|-------------|
| **strong** | effective_score >= 10 OR age > 30 days with 0 contradictions | Always apply, override defaults |
| **moderate** | Standard promotion criteria met | Apply when relevant, don't force |
| **tentative** | Just promoted (score 5-7, age < 14 days) | Apply gently, monitor for contradiction |

Tier is dynamic — recalculated on each new signal or contradiction:
- Tier can upgrade: moderate → strong (score grows or age passes 30 days)
- Tier can downgrade: strong → moderate (contradiction appears)

### Demote (Layered)

Contradictions are handled based on the instinct's current tier:

| Situation | Action |
|-----------|--------|
| 1 contradiction on `tentative` | Demote back to Candidate |
| 1 contradiction on `moderate` | Reduce tier to tentative, note the contradiction |
| 1 contradiction on `strong` | Note it only (may be an anomaly), no tier change |
| 2 contradictions within 7 days (any tier) | Demote to tentative |
| 3+ total contradictions | Retire |
| Explicit denial ("这不是我的习惯", "stop doing that") | Immediate retire regardless of tier |

#### Contradiction decay

Contradictions older than 60 days without repetition lose potency:
- On each instinct check: if oldest contradiction is 60+ days ago and no new contradictions since, reduce contradiction count by 1
- This prevents one-off anomalies from permanently weakening a strong pattern

### Active Influence (how instincts reshape the pipeline)

Confirmed instincts go beyond passive Step 2 style hints — they actively influence the entire QA pipeline based on category:

#### focus-areas → Step 0 retrieval weighting

When qa-guide Step 0.2 retrieves memory via index grep:
- Extract target keywords from each `focus-areas` instinct's action
- Add these keywords to the grep search (OR logic — additive, never removes user keywords)
- Entries matching a focus-areas target get relevance boost: LOW → MEDIUM, or MEDIUM → HIGH
- Maximum 2 entries boosted per instinct (prevent flooding)

#### workflow → Step 0 context preloading

Workflow instincts capture time/context patterns that trigger preloading:
- If a workflow instinct's condition matches current context (day of week, session pattern, preceding question types):
  - Add the predicted category's keywords to Step 0.2 grep search
- Only apply workflow instincts with tier `strong` or `moderate`
- If prediction is wrong (user doesn't ask about predicted topic): no penalty, no action

#### answer-style → Step 2 formatting (tiered strength)

- **tentative**: lean toward the action — if natural answer is medium-length and instinct says "控制篇幅", make it slightly shorter
- **moderate**: apply as default style — structure the answer per the instinct unless question demands otherwise
- **strong**: apply unconditionally — even if question seems to call for different style, trust the instinct

#### correction-patterns → Step 2 negative constraints (tiered enforcement)

- **tentative**: preference level — avoid when possible, but acceptable if technically necessary
- **moderate**: rule level — always avoid, find alternatives
- **strong**: hard block — never do this, period

### Apply (used by qa-guide)

qa-guide Step 0.5 reads Confirmed section and extracts actions:
1. Read only `## Confirmed` entries
2. Parse each entry's `category`, `confidence` tier, and `action`
3. Apply immediately based on category:
   - `focus-areas` and `workflow`: affect Step 0 retrieval (active influence)
   - `answer-style` and `correction-patterns`: record for Step 2 application
4. Return structured guidance for qa-guide to follow

### Show (manual trigger)

When user asks about their patterns:
1. Show Confirmed instincts in friendly format:
   > 根据我的观察，你有这些习惯：
   > - 喜欢先看结论再看分析（确信度：高，观察了5次）
   > - 偏好简洁回答（确信度：高，连续4周）
2. If user says "不对" about any: immediately retire that instinct
3. If user confirms a Candidate: promote immediately
4. Show Candidates as "还在观察中" items if user wants to see them

## Pattern categories

| Category | What to observe | Example actions |
|----------|----------------|-----------------|
| `answer-style` | Response length, structure, code vs text preference | "先结论后分析", "控制在5行内", "用中文" |
| `focus-areas` | Which topics get asked about repeatedly | "优先关注 XX 领域上下文", "检索时加权 YY 相关" |
| `workflow` | Time patterns, session patterns, query sequences | "上午问架构下午问实现" |
| `correction-patterns` | What user consistently corrects | "不要用英文术语", "不要太发散", "别给我选择题" |

## Entry format

### Confirmed entry

```markdown
### INST-NNN: [Pattern title]
- **category**: answer-style | focus-areas | workflow | correction-patterns
- **signals**: [effective_score] ([raw_count] signals, [first date] 首次, [latest date] 最近)
- **evidence**: [2-3 concrete examples of the observed behavior]
- **action**: [specific instruction for qa-guide to follow]
- **confidence**: strong | moderate | tentative (score: N, age: N days)
- **contradictions**: [count] (last: YYYY-MM-DD or "none")
- **active_influence**: step0 | step2 | both
```

Field notes:
- `effective_score`: sum of weighted signals, not raw count
- `confidence`: tier + supporting data for recalculation
- `active_influence`: `step0` for focus-areas/workflow, `step2` for answer-style/correction-patterns, `both` if applicable
- Old entries missing these new fields default to: confidence=moderate, active_influence=step2

### Candidate entry

```markdown
### INST-C-NNN: [Pattern title]
- **category**: [category]
- **signals**: [effective_score] ([raw_count] signals, [first date], [latest date])
- **evidence**: [observed behaviors]
- **action**: (待确认) [tentative action]
- **confidence**: low
- **needs**: [what additional evidence would promote this]
```

### Retired entry

```markdown
### INST-R-NNN: [Pattern title]
- **retired_reason**: [why invalidated]
- **retired_date**: YYYY-MM-DD
- **was_tier**: [last confidence tier before retirement]
```

## ID scheme

- Confirmed: INST-001, INST-002, ...
- Candidates: INST-C-01, INST-C-02, ...
- Retired: INST-R-01, INST-R-02, ...

On promotion: Candidate INST-C-03 becomes INST-NNN (next available confirmed ID).

## Initialization

If `.ask-buddy/memory/instincts.md` doesn't exist, create:

```markdown
# Instincts

> 观察到的用户行为模式

## Confirmed

## Candidates

## Retired
```

## Error handling

- File missing: create from template
- File corrupted: backup to `_backup/`, recreate template
- Never block Q&A flow — instincts are enhancement, not dependency
- If instincts file is unavailable, qa-guide proceeds normally without them

## Constraints

- Maximum 10 Confirmed instincts (if exceeded, retire least-used one)
- Maximum 15 Candidates (if exceeded, prune oldest with signals=1)
- Never record personal information, only work behavior patterns
- Don't create instincts from a single ambiguous observation; an explicit correction may create a non-active Candidate immediately
