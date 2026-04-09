# CI workflow map (MPAS-Model-CI)

Maintainer reference: how workflows connect and where logic lives. For a shorter overview, see [AGENT_GUIDE.md](../.github/AGENT_GUIDE.md).

## Reusable workflows (`workflow_call`)

| Workflow | Purpose | Called by |
|----------|---------|-----------|
| `_test-compiler.yml` | CPU build + ECT | `test-{gcc,intel,nvhpc}-{mpich,openmpi}.yml` (subset callers) |
| `_test-gpu.yml` | NVHPC OpenACC build + ECT on CIRRUS | `test-gpu-mpich.yml`, `test-gpu-openmpi.yml` |
| `_test-bfb.yml` | Bit-for-bit variants | `bfb-io.yml`, `bfb-decomp.yml` |
| `_resolve-nvhpc-containers.yml` | Resolve NVHPC CPU + CUDA images from `ci-config.env` | `_test-gpu.yml`, `compile-nvhpc-cuda-mpich.yml` |

## Caller workflows (thin entry points)

| Caller | Trigger | Invokes |
|--------|---------|---------|
| `test-*-mpich.yml` | push/PR `master`, `develop` | `_test-compiler` |
| `test-*-openmpi.yml` | `workflow_dispatch` | `_test-compiler` |
| `test-gpu-*.yml` | `workflow_dispatch` | `_test-gpu` |
| `compile-nvhpc-cuda-mpich.yml` | push/PR + dispatch | `_resolve-nvhpc-containers` (then compile job) |
| `coverage.yml` | push `master` | (standalone) |
| `unit-tests.yml` | push/PR | (standalone) |
| `ect-test.yml`, `ect-ensemble-gen.yml` | dispatch / manual | (standalone) |
| `profile-gpu-nsight.yml` | `workflow_dispatch` | stub on `master` until full CIRRUS workflow merges |

## Composite actions (shared steps)

| Action | Role |
|--------|------|
| `resolve-container` | Image string from `ci-config.env` |
| `build-mpas` | Make MPAS-A |
| `download-testdata` | Release asset → case dir |
| `run-mpas` / `run-perturb-mpas` | Model runs |
| `validate-ect` | PyCECT |
| `checkout-mpas-source` | Cross-repo + CI overlay |

## Duplication addressed in this refactor

- **NVHPC container resolution** (CPU + CUDA image names) was repeated in `_test-gpu.yml` `config` job and `compile-nvhpc-cuda-mpich.yml`. Centralized in **`_resolve-nvhpc-containers.yml`**.

## Extension points

- New **CPU subset**: add `test-<compiler>-<mpi>.yml` calling `_test-compiler` with `compiler` / `mpi` inputs.
- New **GPU ECT subset**: add `test-gpu-<mpi>.yml` calling `_test-gpu` with `mpi`.
- Container tags / mappings: edit **`.github/ci-config.env`** only; avoid hardcoding image names in YAML.
