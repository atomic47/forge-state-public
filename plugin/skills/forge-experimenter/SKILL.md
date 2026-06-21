---
name: forge-experimenter
description: Use when a forge experiment is at phase `built` and needs a bounded real-world experiment run against it inside the Docker sandbox. Skipped automatically for `build-failed` experiments (they route straight to reporter). Trigger via "/forge-experimenter EXP-NNNN", or invoked by forge-orchestrator. Picks a template per spec §10 taxonomy (cli / library / webapp / mcp / service / model), runs it in the same or a fresh container, captures observations and artifacts (screenshots, sample outputs), advances phase to `experimented`.
---

# forge-experimenter — classify type → template → bounded run

Mode is **hybrid** (manifest.experiment.mode): classify, pick a template, improvise within bounds. Templates prevent flailing; improvisation keeps it useful.

## When to use

- An experiment is at phase `built` (skip if `build-failed`).

## Inputs

- `experiment.yaml` — already has `experiment.type` from the builder.
- The built working copy + container image from the builder.
- A comparables list from the research block (for cli-style A/B).

## Outputs

- `experiment.experiment.{template, steps[], observations, result}` populated.
- `experiments/EXP-NNNN-<slug>/artifacts/` — screenshots, sample outputs, harness scripts.
- Phase advanced to `experimented`.

## Templates (spec §10)

| type | template | what to do |
|---|---|---|
| cli | `cli-sample-input` | run against a curated sample input; A/B against the named comparable on the same input |
| library | `library-headline-api` | 20-line harness exercising the headline API; capture output |
| webapp | `webapp-boot-probe` | boot dev server; curl health/route; screenshot via headless browser |
| mcp | `mcp-list-and-call` | connect, list tools, call one with a known-safe payload |
| service | `service-compose-probe` | `compose up`; probe declared port; capture response |
| model | `model-one-inference` | load weights; run one inference on a fixture |

## Procedure

1. `forge-state read` the EXP record; abort if phase != `built`.
2. Select template from the table above based on `experiment.type`.
3. Build a fresh container from the build image (or reuse) — same egress policy, same caps.
4. Execute template steps inside the container; capture stdout, exit codes, durations, and artifacts.
5. Synthesize:
   - `steps[]`: human-readable list of what was done.
   - `observations`: 2–6 sentences, factual.
   - `result`: `success` (template completed, observations are interesting), `partial` (template completed, results equivocal), `failed` (template ran but produced nothing usable).
6. Save artifacts to `experiments/EXP-NNNN-<slug>/artifacts/` via `forge-state write`.
7. `forge-state advance-phase EXP-NNNN experimented`.

## Error handling

- Template cannot select sample input → record `result: failed`, observations note "no representative input available," still advance.
- Timeout inside template → terminate, record partial observations.
- Network needed beyond registries-only → record `result: failed` with reason; do not weaken egress policy.

## References

- Spec §10 (experiment taxonomy), §2.4 (isolation), §9 (sandbox), §6 (lifecycle).
