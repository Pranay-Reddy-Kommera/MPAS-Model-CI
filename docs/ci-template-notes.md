# Adapting this CI layout for other NCAR projects

This document describes what is **MPAS-specific** versus **portable** when copying patterns from `NCAR/MPAS-Model-CI`.

## Portable patterns

- **Central env file** (here: `.github/ci-config.env`) — single source for image templates, release asset tags, and MPI flags. Forks should rename variables only if semantics change.
- **`resolve-container` composite** — maps `(compiler, mpi, optional gpu)` to a Docker image string from templates.
- **Thin caller workflows** — `on:` + `jobs: { call: reusable with inputs }`. Add a new subset by copying one caller and changing inputs.
- **Reusable workflows** — `_test-compiler.yml`-style templates for “build + test + report” pipelines.
- **`_resolve-nvhpc-containers.yml`** — shared NVHPC CPU + CUDA image resolution for any workflow that needs both strings.

## MPAS-specific pieces (replace when porting)

- **`build-mpas`**, **`run-mpas`**, **`run-perturb-mpas`**, **`validate-ect`** — assume MPAS-A layout, `atmosphere_model`, namelist/streams, ECT/PyCECT


## Infrastructure you must supply

- **Container registry**: images matching `ci-config.env` templates (e.g. `ncarcisl/hpcdev-x86_64` tags), or change templates to your registry.
- **Self-hosted runners**: GPU workflows reference `CIRRUS-4x8-gpu` (or your org’s runner group). Update `runs-on:` to match.
- **GitHub Actions permissions**: workflows generally use `contents: read`; artifact upload itself does not require `actions: write`.
  Use elevated permissions only for specific operations, such as deleting artifacts via `gh api` (`actions: write`) or publishing releases (`contents: write`).

## Minimal fork checklist

1. Copy `.github/ci-config.env`, `resolve-container`, and any composite actions you need.
2. Replace container templates and `MAKE_TARGET_*` / compiler mappings for your build system.
3. Replace or stub `build-mpas` with your model’s build steps.
4. Point `download-testdata` (or equivalent) at your release assets and env tags.
5. Rename workflows and badges in `README.md`; keep caller → reusable structure.
6. Run a **CPU subset** on GitHub-hosted `ubuntu-latest` before relying on self-hosted GPU runners.

For the full workflow inventory, see [ci-workflow-map.md](ci-workflow-map.md).
