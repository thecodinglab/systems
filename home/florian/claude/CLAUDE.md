# Model selection

## Rules

- The user's explicit choices about model, provider, privacy, budget, and effort
  always win. Never route around a restriction.
- Never change the main-session model: no settings edits, alias remaps, or
  restarts. That is the user's call via `/model`. If the user asks which model to
  use, recommend Opus 5.5 for quality-first work and Sonnet 5.5 for routine or
  cost/latency-sensitive work.
- Do trivial work on the current model. Delegate only substantial, separable work,
  and only when specialization, independent review, or context isolation is worth
  the startup cost. Pick the smallest model likely to finish correctly, judged by
  the total cost of a verified result rather than token price.
- When a routing decision changes how substantial work gets done, state it
  briefly. Never claim a model identity that hasn't been confirmed at runtime.

## Routing

| Task | Preferred | Escalation / alternative |
| --- | --- | --- |
| File discovery, extraction, classification, mechanical summaries | `haiku` | `sonnet` if interpretation gets hard |
| Routine edits, tests, docs, straightforward fixes | `sonnet` | `opus` for ambiguity, repeated failures, wider impact |
| Multi-file implementation, unfamiliar repos, refactors with invariants | `opus` | `openai-sol` for an alternative implementation |
| Architecture, trade-offs, risky migrations, subtle Nix/system behavior | `opus` | `fable` for unresolved, high-value reasoning |
| Hard debugging, algorithms, concurrency | `opus` | `openai-astra` for an independent hypothesis; `fable` for deeper reasoning |
| Code review | `openai-sol` for Claude-written changes; `opus` for OpenAI-written changes | `openai-astra` only for unusually hard reviews |
| Security-sensitive / high-impact review | `opus` + one independent reviewer | `openai-astra` or `fable` for the hardest remaining issue |
| Explicit OpenAI tasks | `openai-sol` | `openai-astra` for unresolved reasoning |
| Frontend/UI | `opus` with rendered/browser validation | `sonnet` for routine UI edits |
| Research and technical writing | `sonnet`; `opus` when evidence conflicts | Citations required |
| Image generation/editing | A dedicated image tool | Never the Agent tool |

- Haiku is never the final arbiter for architecture, security, or destructive
  migrations.
- Fable and Astra are for escalation. Don't use them by default.
- Other OpenAI models (GPT 6.0 Luna/Sol, 5.x) only when explicitly requested.
  Never use "Codex Auto Review" for code review: it is an action-approval
  mechanism, not a review model.

## Requesting a model

- Claude delegates: set the Agent tool's `model` to `haiku`, `sonnet`, `opus`, or
  `fable`.
- OpenAI delegates: set `subagent_type: "openai-sol"` (GPT 6.1 Sol) or
  `"openai-astra"` (GPT 6.0 Astra). **Omit `model`**, because it overrides their
  frontmatter. Their gateway IDs start with `claude-fable`, but that does not make
  them `fable`.
- A fork inherits its parent's model, so don't fork when a different model is the
  point of delegating. Don't start nested CLI sessions to get around this.
- OpenAI models run through CLIProxyAPI, which is experimental. Tool calling,
  streaming, context limits, and effort may behave differently. If a route fails or
  an agent is missing, report it. Fall back only if the user's constraints allow
  it, and name the fallback. Don't retry auth errors in a loop or touch
  credentials/proxy settings.

## Delegation and escalation

- Give each delegate a bounded task, the relevant files, acceptance criteria, and
  an explicit read-only or write scope. Allow one writer per file. Share only the
  context the delegate needs, especially with external providers.
- Default to one worker. For consequential changes, add one independent reviewer
  on a different model from the author. A reviewer never edits the code it reviews.
- Keep the configured effort. Per-agent overrides: low for mechanical tasks,
  medium for routine work, high for hard reasoning and review. Don't use
  `max`/`xhigh` by default, and never change persistent effort settings.
- After two distinct failed approaches, escalate once, passing along the
  reproducer, the attempted fixes, and the failing tests. Don't keep rotating
  models; a bigger model can't fill in missing requirements.
- Agreement between models doesn't count as verification. Tests and builds decide.
