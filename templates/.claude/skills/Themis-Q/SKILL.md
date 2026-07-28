---
name: Themis-Q
description: Improve requirement questioning by asking focused, adaptive questions that clarify intent, scope, context, options, acceptance criteria, and risks.
user-invocable: true
---

# Themis-Q

Use disciplined questioning to turn an unclear change request into precise, reviewable requirements.

## Questioning style

- Ask one focused question at a time.
- Prefer concrete choices when the answer space is known; use open questions when discovery is still needed.
- Explain why a question matters only when the relevance is not obvious.
- Adapt depth to uncertainty and impact. Keep simple changes brief; probe cross-system, security, data, compatibility, or irreversible changes more deeply.
- Distinguish the user's requested mechanism from the outcome they actually need.
- Challenge assumptions respectfully and offer a simpler alternative when it better serves the goal.
- Summarize established facts before moving to a new topic when the conversation becomes complex.
- Do not repeat questions whose answers are already clear from the conversation.

## Questioning coverage

Cover the areas that materially affect the requirement. Do not force irrelevant sections.

### Intent

- What observable problem or opportunity motivates the change?
- Who is affected, and what outcome should improve?
- Why is the requested change needed now?
- Would solving the stated mechanism leave the underlying problem unresolved?

### Scope

- What behavior is included?
- What is explicitly excluded?
- Which users, systems, interfaces, data, or workflows may be affected?
- What constraints or compatibility expectations bound the change?

### Context and assumptions

- Which current behaviors or project facts does the request rely on?
- Which statements are verified facts, assumptions, preferences, or unknowns?
- What missing or conflicting information could change the solution or acceptance criteria?
- How will important assumptions be validated?

### Options and trade-offs

- What happens if nothing changes?
- Is there a smaller or more direct option?
- For meaningful alternatives, what are the trade-offs in behavior, complexity, risk, operability, and reversibility?
- Which option does the user prefer, and why?

### Requirements and acceptance

- Express required behavior in observable terms.
- Identify interfaces, contracts, invariants, and failure behavior when relevant.
- Ask for measurable success conditions.
- Form acceptance criteria as concrete Given/When/Then outcomes where useful.
- Present no more than three acceptance criteria at a time for review.

### Risks and edge cases

Read [references/adversarial-checklist.md](references/adversarial-checklist.md) when the change warrants adversarial questioning.

- Probe boundaries, failure states, concurrency, compatibility, rollback, security, dependencies, state transitions, and data integrity as applicable.
- Tie each valid concern to a concrete scenario and affected requirement or acceptance criterion.
- Distinguish concerns that must be covered now from accepted risks or explicitly deferred work.
- Do not dilute critical security, permission, or data-integrity concerns into vague follow-up notes.

## Convergence

When the important uncertainties are resolved, summarize:

- intent and desired outcome;
- included and excluded scope;
- verified context and remaining assumptions;
- selected option and trade-offs;
- requirements and acceptance criteria;
- material risks, edge cases, and rollback expectations.

Ask the user to correct anything inaccurate or incomplete. Return the clarified requirement in the surrounding conversation's requested format; this Skill does not define lifecycle steps, artifact creation, persistence, or a handoff schema.
