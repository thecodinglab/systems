# Anthropic and OpenAI: model selection for Claude Code

**Research date: 2026-10-13.** Scope: current coding/reasoning models, online
sentiment, and their use through this repository's Claude Code + CLIProxyAPI
configuration. This is a qualitative evidence review, not a representative poll
or a controlled benchmark of this installation.

## Recommendation

Use **Claude Opus 5.5 as the quality-first Claude Code default**, **Sonnet 5.5 for
bounded, economical work**, and **GPT-6.1 Sol as a complementary OpenAI coding
worker and reviewer**. Use **Haiku 5.5 for small, easily checked tasks**. Reserve
**Fable 5.1 and GPT-6 Astra for difficult escalations** rather than paying their
latency/usage cost on every request.

There is no defensible universal winner. A strong implementation model, a cheaper
worker, and a genuinely independent reviewer are more useful than automatically
selecting the newest or most expensive model for everything. These are
recommendations; this configuration deliberately preserves the user's selected
main-session model and existing effort settings.

## Method and confidence

The evidence combines:

- **Official model catalogs and release documentation** to establish names, API
  identifiers, availability, and intended roles. Vendor recommendations are not
  independent performance measurements.
- **Practitioner experiments and evaluations** to test specific claims. Their
  tasks, harnesses, effort settings, languages, and scoring matter.
- **Hacker News discussions** for favorable and unfavorable user experiences.
  These are self-selected anecdotes, not an estimate of all users' preferences.
- **Reddit search results** as low-weight corroboration only: full threads were
  blocked. No sentiment percentages are inferred from snippets or vote counts.

Research prioritized the September/October releases and dissenting evidence.
It was not an exhaustive social-media crawl. Multiple comments in one launch
thread are not independent experiments. Dynamic documentation and leaderboards
are not immutable archives of October 13; some discussions expose only relative
dates. Official OpenAI announcement bodies returned HTTP 403, so accessible
OpenAI API/Codex documentation was used for release verification.

**High confidence:** model identities and documented product roles.
**Moderate confidence:** Opus for quality-first Claude Code work; Sonnet/Sol for
scoped implementation; small models for verifiable tasks.
**Low to moderate confidence:** exact architecture, research, and difficult-debugging
rankings. **Low confidence:** a universal writing winner or equivalence between
native Codex results and translated requests through this proxy.

No paid generation benchmarks or live delegate inference tests were run here.
The local gateway inventory was read without displaying credentials.

## Current model landscape

The recent names were corroborated against public documentation, not inferred
from the local UI alone. Dates below are the releases reported by the linked
provider documentation. See the [Anthropic model catalog][anthropic-models],
[Anthropic newsroom][anthropic-news], [Fable page][fable], and
[OpenAI API changelog][openai-changelog].

| Model | Official API identifier | Release | Working role |
| --- | --- | --- | --- |
| Claude Fable 5.1 | `claude-fable-5-1` | Sep 1, 2026 | Difficult, high-value reasoning escalation |
| Claude Opus 5.5 | `claude-opus-5-5` | Sep 22, 2026 | Quality-first native Claude Code work |
| Claude Sonnet 5.5 | `claude-sonnet-5-5` | Sep 28, 2026 | Routine implementation/value |
| Claude Haiku 5.5 | `claude-haiku-5-5` | Oct 7, 2026 | Small, bounded and verifiable work |
| GPT-6 Astra | `gpt-6-astra` | Sep 3, 2026 | Difficult reasoning and independent escalation |
| GPT-6 Sol | `gpt-6-sol` | Sep 22, 2026 | Previous Sol generation; compatibility alternative |
| GPT-6 Luna | `gpt-6-luna` | Sep 22, 2026 | Narrow tasks with speed/value constraints |
| GPT-6.1 Sol | `gpt-6.1-sol` | Sep 29, 2026 | Preferred complementary OpenAI coding worker |

The gateway also advertises GPT-5.5, GPT-5.6 Luna/Sol/Terra, and older Claude
versions. OpenAI's changelog corroborates the 5.5/5.6 families, but there is no
reason in this evidence to prefer them as new defaults over the current models.
The [Codex model documentation][codex-models] describes GPT-5.5 retirement from
ChatGPT-authenticated Codex on **October 14**, not October 13; that does not imply
simultaneous API retirement. Availability remains account- and endpoint-specific.

The local list also contains GPT Image models. Image generation/editing should
use a compatible dedicated image tool, not a coding-agent route. This review did
not establish a comparative winner among Image 2.5, Flare, and Sunburst.

## Online sentiment: agreement and disagreement

### Opus 5.5: strongest convergence for Claude Code, not flawless

The sampled community discussion leans favorable for implementation quality,
less steering, and longer useful work sessions. The [Opus HN discussion][hn-opus]
also includes complaints about token usage, extra charges, and marginal gains.
Those complaints matter: a successful answer can still be an expensive answer.

[Thomas Wiegold's October 5 comparison][wiegold] favored Opus overall across a
website, a Go interpreter, and a parallel Collatz implementation. The details are
more informative than the overall preference:

- Sol's interpreter was smaller and faster, but deviated from the specified
  grammar, failed on unbounded recursion, and had weaker mutation-test coverage.
- Sol alone fully preserved the Collatz interface; Opus found a much faster
  algorithm. Neither “best benchmark score” nor “fastest code” captures every
  acceptance criterion.
- Three assignments and an acknowledged pre-existing Claude preference do not
  establish a universal ranking. Harness/effort comparability was incomplete.

[Simon Willison's September 22 experiments][willison-launch] selected Opus for
Claude Code and Sol for Codex, but also documented two maximum-effort Opus SVG
runs exhausting 128k output tokens without delivering an answer. **Maximum effort
is not automatically maximum usefulness.**

### Sonnet 5.5: sensible value default for bounded work

Official [Claude Code model guidance][claude-models] positions Sonnet well for
scoped work. Independent composite evaluations also make it competitive, but
there is less task-specific anecdotal evidence than for the flagship launches.
The recommendation is therefore practical and moderately confident, not a claim
that Sonnet matches Opus on every repository or risky change.

### GPT-6.1 Sol: credible implementation partner, with review still necessary

Sol is a strong alternative for clear acceptance criteria and a useful second
model family for review. Native Codex evidence is encouraging, but it must not be
silently treated as a Claude Code + CLIProxyAPI result.

[Sonar's October 9 evaluation][sonar] compared GPT-6 Sol and 6.1 Sol on **4,444 Java
tasks**, of which **544 had executable tests**. Reported test success rose from
**83.09% to 85.29%**, while generated code increased **39.4%** and total
static-analysis findings increased **31.7%**. Findings per line decreased, but
there was still more total code and more total findings to review. Static-analysis
findings are not all proven runtime bugs. The study is Java-only and written by
an analyzer vendor, not a language-neutral, model-provider-independent audit.

The [large HN Sol discussion][hn-sol] contains both “nearly as good and much
cheaper” anecdotes and reports of similar actual achieved cost. Several negative
comparisons concern **GPT-6 Sol or Astra**, not 6.1 Sol; counting them as evidence
against 6.1 would be misleading. A [difficult NURBS anecdote][hn-nurbs] preferred
Opus over Astra and suggested Astra as a reviewer, but neither implementation
fully succeeded.

An [October 9 Codex issue][codex-issue] reports poor Sol 6.1 Ultra+Fast orchestration
and verification. It was open and unconfirmed: it supports caution about
aggressive delegation/settings, not a blanket conclusion that Sol is unreliable.

### Fable 5.1 and Astra: promising escalation, sparse comparative proof

The vendors position them for demanding reasoning. Independent evidence is much
thinner for “best architect,” “best debugger,” or “best researcher” than for the
existence and advertised roles of the models. Start with a strong working model;
escalate a well-defined failure with its evidence. Do not equate price, branding,
or context size with guaranteed superiority. The ordering between Fable and
Astra is particularly uncertain.

### Haiku 5.5 and Luna: bounded work, not final high-risk judgment

[Willison's October 7 Haiku experiments][willison-haiku] found better SVG output
than Haiku 4.5, but did not directly compare Haiku 5.5 with Luna. His earlier Luna
experiments were promising for SQL/HTML/JavaScript apps. This supports small-model
experimentation on verifiable tasks, not using either as sole reviewer of a
security-sensitive migration. Haiku had only six days of public exposure at this
snapshot, so long-term reliability claims would be premature.

### Writing, research, and frontend work: choose evidence over taste

Writing sentiment is mixed. An [80-post Opus 5 versus 5.5 experiment][writing-test]
found reductions in some targeted stylistic habits, alongside longer output and
more bold-prefaced bullets. Some scoring used an imperfect model judge, and the
experiment did not compare an OpenAI writer. [HN opinions][hn-writing] still
criticize robotic or qualification-heavy prose. There is no universal style winner.

For research, retrieval quality and checking original sources matter more than
confidence of prose. For frontend work, the relevant evidence includes rendered
screenshots, interaction checks, and accessibility—not only a model leaderboard
or a polished first screenshot.

### What the leaderboards do and do not establish

[Artificial Analysis][artificial-analysis] supports the competitiveness of the
current Claude models, including Sonnet. Its intelligence composite is not a
code-review, writing, or Nix correctness score; effort configurations differ and
some entries include fallback. It does not establish a universal task winner.

[Model Matchbook's October 12 coding aggregation][model-matchbook] places Opus
and Sonnet highly, but combines different benchmarks and preference arenas. Its
Terminal-Bench comparisons include different Claude Code/Codex harnesses.
Coverage and weighting ambiguities limit its evidential weight. Direct
Terminal-Bench/LiveBench fetches did not expose enough rows to independently
confirm the aggregation; its scores are not presented here as success rates.

Reddit search results ([thread one][reddit-one], [thread two][reddit-two]) showed
both everyday Sol preference and preference for Opus on harder debugging. Because
full threads were inaccessible, they do not establish Reddit-wide consensus.

## Which model for which action?

These are working priorities, not statistically proven head-to-head rankings.
The installed policy turns them into bounded delegation rules.

| Action | First choice | Alternative or escalation | Confidence |
| --- | --- | --- | --- |
| General, quality-first Claude Code session | Opus 5.5 | Sonnet 5.5 for value | Moderate |
| Mechanical extraction, classification, bounded summaries | Haiku 5.5 | Sonnet; Luna for explicit OpenAI work | Moderate for role |
| Routine edits, docs, tests, straightforward bugs | Sonnet 5.5 | Sol 6.1 worker; Opus for assurance | Moderate |
| Multi-file implementation and unfamiliar code | Opus 5.5 | Sol 6.1 for a scoped alternative | Moderate |
| Architecture, migrations, subtle system/Nix invariants | Opus 5.5 | Fable; Astra as independent alternative | Low–moderate |
| Stubborn debugging, algorithms, concurrency | Opus plus reproducer | Fable or Astra after evidence-led failure | Low–moderate |
| Review of Claude-authored code | Sol 6.1 | Astra for unusually difficult review | Moderate workflow; low exact ranking |
| Review of OpenAI-authored code | Opus 5.5 | Fable for unusually difficult review | Moderate workflow; low exact ranking |
| High-impact/security-sensitive change | Strong implementer plus independent reviewer | Tests and threat analysis, not model voting | Moderate workflow |
| Technical research/synthesis | Opus for conflicting evidence; Sonnet for bounded sources | Fable/Astra for exceptional complexity | Low–moderate |
| Writing/editing | Opus for nuance; Sonnet for routine docs | Fable/Sol as a style alternative | Low |
| Frontend/UI | Opus with visual/interaction checks | Sonnet for straightforward UI work | Low–moderate |
| Long autonomous run | Opus with checkpoints and bounded workers | Controlled Fable/Astra trials | Low–moderate |

A different reviewer is a useful error-discovery heuristic, not a demonstrated
multiplicative reliability guarantee. Models can share blind spots. Concrete
reproducers, tests, code locations, and explicit uncertainty remain mandatory.

For scoped work, official Claude guidance recommends medium effort on Opus/Sonnet;
Fable's difficult-work recommendation is high. This repository already specifies
high effort; the change does not rewrite that preference. Per-delegate low/medium/
high effort can be requested when supported. Do not normalize effort labels across
providers, or automatically use `max`/`xhigh` for everything.

Nominal API token price is only one part of cost. Subscription quotas, retries,
cache behavior, output length, tool loops, context size, and time spent fixing a
wrong patch can dominate. Gateway access does not prove that a request is free or
covered by a particular subscription. No dollar savings are promised here.

## Routing in this installation

A read-only `GET /v1/models` against the local CLIProxyAPI instance advertised:

| Public model | Gateway display label | Gateway request ID |
| --- | --- | --- |
| Fable 5.1 | Claude Fable 5.1 | `claude-fable-5-1` |
| Opus 5.5 | Claude Opus 5.5 | `claude-opus-5-5` |
| Sonnet 5.5 | Claude Sonnet 5.5 | `claude-sonnet-5-5` |
| Haiku 5.5 | Claude Haiku 5.5 | `claude-haiku-5-5` |
| GPT-6 Astra | GPT 6.0 Astra | `claude-fable-5-dd-artsa-6-tpg` |
| GPT-6.1 Sol | GPT 6.1 Sol | `claude-fable-5-dd-los-1.6-tpg` |
| GPT-6 Luna | GPT 6.0 Luna | `claude-fable-5-dd-anul-6-tpg` |
| GPT-6 Sol | GPT 6.0 Sol | `claude-fable-5-dd-los-6-tpg` |

**A display name, an advertised route, and the answering upstream are three
different things.** The Claude-shaped OpenAI IDs are proxy routes, not official
Anthropic model IDs. The list establishes advertised availability only. No inference
or backend-identity verification was performed, and routes must not be synthesized
by guessing an encoding scheme.

The proxy's **Codex Auto Review** entry is deliberately excluded from review
recommendations. Official [Codex Auto-review documentation][auto-review] describes
an action-approval agent evaluating sandbox escalations, not a standalone
public general-purpose code-review model. The exposed gateway entry has not been
validated for ordinary code review.

[Claude Code memory documentation][claude-memory] treats `CLAUDE.md` as context,
not enforced settings. It cannot switch the main model. `/model`, `--model`, model
settings, and subagent configuration are actual selection mechanisms. The policy
must not claim to have changed a parent session merely by choosing a model name.

For ordinary delegates, the tool's supported `haiku`, `sonnet`, `opus`, and `fable`
values are used. They currently map to the versions above but may be overridden
or move with a release. For OpenAI, two [named subagents][claude-subagents] use
full gateway IDs in their `model` frontmatter:

- `openai-sol`: bounded implementation/testing and independent review with Sol 6.1.
- `openai-astra`: difficult debugging/reasoning and exceptional review escalation.

Invoke either by `subagent_type` **without a per-call `model` override**, which
would supersede its configured route. A fork inherits the parent and is not a
cross-model routing mechanism. Each named delegate is bounded to 24 turns;
neither configuration sets permission bypasses, effort overrides, or a fallback
chain. No alias is remapped and no global default model is pinned by Nix.

[Anthropic's gateway documentation][claude-gateways] explicitly does not support
routing Claude Code to non-Claude models through gateways. [CLIProxyAPI][proxy]
is an existing third-party integration here, not a guarantee of equivalent
native Codex behavior. Named agents use the documented full-ID selection surface,
but their actual translated inference/tool compatibility remains untested.
On route/authentication/tool failure, report it and choose an allowed, explicitly
identified fallback rather than silently changing providers or retrying forever.

## Declarative integration and validation

The configuration installs the following for `florian` on **desktop, macmini,
and macbookpro** (the repository's MacBook host name):

| Installed file | Repository source |
| --- | --- |
| `~/.claude/CLAUDE.md` | `home/florian/claude/CLAUDE.md` |
| `~/.claude/model-selection-report.md` | `docs/ai-model-selection.md` |
| `~/.claude/agents/openai-sol.md` | `home/florian/claude/agents/openai-sol.md` |
| `~/.claude/agents/openai-astra.md` | `home/florian/claude/agents/openai-astra.md` |

`modules/home-manager/claude-code.nix` supplies the optional
`custom.claude-code.context` option (path, inline text, or null).
`home/florian/default.nix` selects the global policy and installs the reference
report and agents. All three hosts import that shared user profile; no duplicated
host-specific policy or secret is needed. The full report is not imported into
every prompt. Auto-memory being disabled does not disable explicit `CLAUDE.md`.

The files become read-only Nix-managed links. Edit their repository sources and
rebuild; do not ask Claude to rewrite the installed copies. Existing interactive
model selection, proxy settings, permission settings, and effort remain intact.

Useful validation commands after adding the new sources to Git:

```sh
nix fmt -- --check modules/home-manager/claude-code.nix home/florian/default.nix
nix eval --raw '.#darwinConfigurations.macmini.config.home-manager.users.florian.home.file.".claude/CLAUDE.md".source'
nix eval --raw '.#darwinConfigurations.macbookpro.config.home-manager.users.florian.home.file.".claude/CLAUDE.md".source'
nix eval --raw '.#nixosConfigurations.desktop.config.home-manager.users.florian.home.file.".claude/CLAUDE.md".source'
```

Normal Git-backed flakes exclude brand-new untracked sources. Testing before
staging should use a temporary snapshot containing tracked files and only the
intended new sources, not a wholesale copy of the working directory or credentials.
No staging or lockfile update is required for that approach.

Activation remains a separate system operation: use the repository's normal
`make build HOST=<host>` / `make switch HOST=<host>` workflow on each host after
reviewing all pending configuration changes. In a new Claude session, `/memory`
should show the global policy and `/agents` should show the two named delegates.
Inspect the requested/actual route during a real bounded task before relying on
cross-provider behavior. A configuration evaluation is not an inference test.

Reassess roughly monthly while using the policy, or sooner after a model release,
route change, regression, or pricing/quota change. Prefer a small local acceptance
suite of real tasks over launch excitement. Do not automatically rewrite this
policy from a single anecdote or repeatedly search the web on every action.

## Sources

### Official model and product documentation

- [Anthropic model overview][anthropic-models]
- [Anthropic newsroom][anthropic-news] and [Fable product page][fable]
- [OpenAI API changelog][openai-changelog]
- [Codex model guidance][codex-models]
- [Codex Auto-review: action-approval documentation][auto-review]

### Independent/practitioner evidence and community discussions

- [Thomas Wiegold: GPT-6.1 Sol review, October 5][wiegold]
- [Sonar: GPT-6.1 Sol Java evaluation, October 9][sonar]
- [Simon Willison: Opus, Sol and Luna experiments, September 22][willison-launch]
- [Simon Willison: Haiku 5.5 experiments, October 7][willison-haiku]
- [Artificial Analysis intelligence leaderboard][artificial-analysis]
- [Model Matchbook coding aggregation, October 12][model-matchbook]
- [HN: Opus discussion][hn-opus], [Sol discussion][hn-sol],
  [NURBS anecdote][hn-nurbs], and [writing discussion][hn-writing]
- [Opus writing-comparison repository][writing-test]
- [Codex issue: Sol orchestration/verification complaint, October 9][codex-issue]
- [Reddit coding-model thread][reddit-one] and [Sol Plus-user thread][reddit-two]
  (search snippets only; full threads inaccessible)

### Claude Code selection and integration mechanics

- [Model configuration][claude-models]
- [Subagent configuration and model precedence][claude-subagents]
- [Memory and global CLAUDE.md][claude-memory]
- [Gateway support and limitations][claude-gateways]
- [CLIProxyAPI repository][proxy]

[anthropic-models]: https://platform.claude.com/docs/en/about-claude/models/overview
[anthropic-news]: https://www.anthropic.com/news
[fable]: https://www.anthropic.com/claude/fable
[openai-changelog]: https://developers.openai.com/api/docs/changelog
[codex-models]: https://learn.chatgpt.com/docs/models
[auto-review]: https://learn.chatgpt.com/codex/sandboxing/auto-review
[wiegold]: https://thomas-wiegold.com/blog/gpt-6-1-sol-review/
[sonar]: https://www.sonarsource.com/blog/openai-gpt-6-1-sol-evaluation/
[willison-launch]: https://simonwillison.net/2026/Sep/22/opus-and-sol-and-luna/
[willison-haiku]: https://simonwillison.net/2026/Oct/7/claude-haiku-5-5/
[artificial-analysis]: https://artificialanalysis.ai/leaderboards/models
[model-matchbook]: https://modelmatchbook.com/best/coding
[hn-opus]: https://news.ycombinator.com/item?id=49850798
[hn-sol]: https://news.ycombinator.com/item?id=49896586
[hn-nurbs]: https://news.ycombinator.com/item?id=49897552
[hn-writing]: https://news.ycombinator.com/item?id=49803951
[writing-test]: https://github.com/jimbobbennett/claude-compare
[codex-issue]: https://github.com/openai/codex/issues/52643
[reddit-one]: https://www.reddit.com/r/OpenaiCodex/comments/1wu425d/what_model_do_you_use_for_coding_tasks/
[reddit-two]: https://www.reddit.com/r/codex/comments/1wtq7vg/gpt61_sol_is_very_good_for_the_plus_users/
[claude-models]: https://code.claude.com/docs/en/model-config
[claude-subagents]: https://code.claude.com/docs/en/sub-agents
[claude-memory]: https://code.claude.com/docs/en/memory
[claude-gateways]: https://code.claude.com/docs/en/gateways
[proxy]: https://github.com/router-for-me/CLIProxyAPI
