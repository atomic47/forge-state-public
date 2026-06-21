---
name: forge-publisher
description: Use when a forge experiment is at phase `reported` and needs its outputs shipped — gist (auto), scsiwyg blog post (auto-publish, locked-on per project decision), and a work-state event emission. Scrubs secrets before every send. Trigger via "/forge-publisher EXP-NNNN" or invoked by forge-orchestrator. Advances phase to `published`.
---

# forge-publisher — fan out outputs (gist + blog + work-state)

Two senses of "deploy" are both covered (spec §12): the writeup (gist + blog + report) and the code (deploy bundle, image if pushed). The signal is the work-state event.

## When to use

- Phase `reported`.

## Inputs

- `experiment.yaml`, `report.md`, `build/env.json`, `deploy/*`.
- Secret store refs from manifest.secrets (anthropic, slack, github, scsiwyg).

## Outputs

- `experiment.outputs.gist_url`.
- `experiment.outputs.blog_post_id` and `blog_status: published` (locked auto-publish).
- work-state event emitted (`build` + `publish`).
- `experiment.events_emitted: [build, publish]`.
- Phase advanced to `published`.

## Procedure

1. `forge-state read` the EXP.
2. **Scrub.** Read all artifacts to be shipped (report.md, env.json snippets, log tails); call `forge-state scrub-secrets` on every payload before any network send.
3. **Gist.**
   - Compose gist files: `README.md` (the report), `experiment.yaml` (sanitized copy without internal paths), `env.json` (verbatim — the reproducibility anchor), `RUN.md` if present.
   - Create gist via GitHub API (public, description = "forge EXP-NNNN: <slug>").
   - Record `outputs.gist_url`.
4. **Blog.**
   - Compose scsiwyg post body from report.md, inserting the gist URL as the reproducibility link and the image ref as the run-it link.
   - Post to scsiwyg via its API; locked to auto-publish (manifest.surfaces.blog.auto: true).
   - Record `outputs.blog_post_id`, `outputs.blog_status: published`.
5. **work-state event.** Emit `build` and `publish` events via the work-state facility (one-shot file drop into work-state's intake, or direct API if available). Mirror this activity so work-state can harvest forge's own output.
6. **Run summary line** for the nightly summary (handed back to orchestrator): "EXP-NNNN <slug>: <result> → gist + blog".
7. `forge-state advance-phase EXP-NNNN published`.

## Error handling

- Gist 4xx/5xx → retry once; on second failure, record error, leave phase at `reported`, surface in orchestrator summary.
- Blog publish failure → fall back to draft; record `blog_status: draft` and surface the failure.
- Scrub turns up a secret in the payload → log a high-severity activity event and abort send; this is a defect, not a routine condition.

## References

- Spec §12 (publishing), §15 (secrets — scrub is mandatory), §17 (observability — events are the longitudinal view), §18.1/.2 (locked: push + auto-publish).
