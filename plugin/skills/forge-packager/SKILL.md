---
name: forge-packager
description: Use when a forge experiment is at phase `experimented` and needs to be turned into a shareable, runnable artifact — a deploy/ bundle (Dockerfile, compose.yaml, RUN.md). Also pushes the image to GHCR (locked-on per project decision; token at env $GHCR_TOKEN, registry ghcr.io/davidolsson). Skipped on `build-failed` experiments. Trigger via "/forge-packager EXP-NNNN" or invoked by forge-orchestrator. Reuses the build's env manifest so packaged artifact and gist agree on environment.
---

# forge-packager — emit deploy bundle, push image

## When to use

- An experiment is at phase `experimented`.
- Never on `build-failed` (the reporter notes "not packaged" with reason).

## Inputs

- The build image from forge-builder.
- `build/env.json` — base image digest, runtime versions, exact commands.
- `experiment.experiment.type` — for choosing the RUN.md invocation.
- Manifest: `packaging.push_image: true`, `packaging.registry: ghcr.io/davidolsson`.
- Env: `GHCR_TOKEN` (host-only; never enters the data plane).

## Outputs

- `experiments/EXP-NNNN-<slug>/deploy/Dockerfile` — self-contained, uses pinned base image digest.
- `experiments/EXP-NNNN-<slug>/deploy/compose.yaml` — one-service compose with sensible defaults.
- `experiments/EXP-NNNN-<slug>/deploy/RUN.md` — the exact `docker run` / `compose up` invocation + what it does + what to expect.
- Image pushed to `ghcr.io/davidolsson/forge-<slug>:exp-NNNN` (and `:latest`).
- `experiment.package.{dockerfile_ref, compose_ref, run, image}` populated.
- Phase advanced to `packaged`.

## Procedure

1. `forge-state read` the EXP; abort if phase != `experimented`.
2. Generate `Dockerfile`:
   - `FROM <base-image>@<digest>` from `build/env.json`.
   - `WORKDIR /app`, `COPY . .`, the build commands from `env.json`, the entrypoint matching `experiment.type` (CMD for cli/library, EXPOSE+CMD for webapp/service/mcp).
3. Generate `compose.yaml`: one service, port mapping if applicable, restart policy, resource limits matching `manifest.sandbox`.
4. Generate `RUN.md`: title, one-paragraph what-it-does, the exact `docker run --rm <image> <args>` line (or `docker compose up`), expected output, link to gist.
5. Build and tag the image locally: `docker build -t ghcr.io/davidolsson/forge-<slug>:exp-NNNN .`
6. If `$GHCR_TOKEN` is set and `packaging.push_image: true`:
   - `echo $GHCR_TOKEN | docker login ghcr.io -u davidolsson --password-stdin`
   - `docker push ghcr.io/davidolsson/forge-<slug>:exp-NNNN`
   - Tag and push `:latest`.
   - Record image ref in `package.image`.
7. If push fails or token missing → log warning, leave `package.image: null` (bundle alone is still valid).
8. `forge-state advance-phase EXP-NNNN packaged`.

## Error handling

- Push failure → continue with bundle-only; warn in activity log.
- Missing env.json → cannot pin digest; abort with structured error (builder is the prereq).

## References

- Spec §11 (packaging), §2.7 (no secrets in outputs — token used host-side only), §18.1 (locked: push enabled).
