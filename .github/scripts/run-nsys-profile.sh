#!/usr/bin/env bash
# Run MPAS-A under Nsight Systems (nsys profile). Intended for CIRRUS GPU CI.
# Usage: run-nsys-profile.sh <workdir> <num-procs> <mpi-impl> <timeout-minutes> <nsys-output-basename>
set -euo pipefail

WORKDIR="${1:?workdir required}"
NUM_PROCS="${2:?num-procs required}"
MPI_IMPL="${3:?mpi-impl required}"
TIMEOUT="${4:?timeout minutes required}"
NSYS_BASENAME="${5:?nsys output basename required}"

if [ -f /container/config_env.sh ]; then
  # shellcheck source=/dev/null
  source /container/config_env.sh
fi

if [ -z "${LD_LIBRARY_PATH:-}" ]; then
  export LD_LIBRARY_PATH="/usr/lib64:/usr/lib"
fi

REPO_ROOT="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
CI_CONFIG="${REPO_ROOT}/.github/ci-config.env"
if [ -f "${CI_CONFIG}" ]; then
  # shellcheck source=/dev/null
  source "${CI_CONFIG}"
fi

# Locate nsys (not always on default PATH in minimal images)
if ! command -v nsys &>/dev/null; then
  for d in /opt/nvidia/nsight-systems/*/bin /usr/local/cuda/bin /usr/local/cuda-*/bin; do
    if [ -d "$d" ]; then
      export PATH="${d}:${PATH}"
    fi
  done
fi
if ! command -v nsys &>/dev/null; then
  echo "::error::nsys (Nsight Systems) not found. Install Nsight Systems or use an image that includes it."
  exit 1
fi

echo "=== nsys ==="
nsys --version

MPI_FLAGS=""
if [ "${MPI_IMPL}" = "openmpi" ]; then
  MPI_FLAGS="${OPENMPI_RUN_FLAGS:---allow-run-as-root --oversubscribe}"
elif [ "${MPI_IMPL}" = "mpich" ]; then
  export MPICH_GPU_SUPPORT_ENABLED="${MPICH_RUN_ENV_MPICH_GPU_SUPPORT_ENABLED:-0}"
  export MPIR_CVAR_ENABLE_GPU="${MPICH_RUN_ENV_MPIR_CVAR_ENABLE_GPU:-0}"
fi

ulimit -s unlimited 2>/dev/null || true

cd "${WORKDIR}"

OUT_ABS="${PWD}/${NSYS_BASENAME}"
echo "=== Nsight profile ==="
echo "  workdir: ${WORKDIR}"
echo "  ranks:   ${NUM_PROCS}"
echo "  mpi:     ${MPI_IMPL}"
echo "  output:  ${OUT_ABS}"
echo "  timeout: ${TIMEOUT}m"

set +e
timeout "${TIMEOUT}"m nsys profile \
  --trace=cuda,nvtx,osrt \
  --stats=true \
  -o "${OUT_ABS}" \
  mpirun -n "${NUM_PROCS}" ${MPI_FLAGS} ./atmosphere_model
RUN_STATUS=$?
set -e

if [ "${RUN_STATUS}" -ne 0 ]; then
  echo "::warning::Profiled run exited with status ${RUN_STATUS}"
  exit "${RUN_STATUS}"
fi

echo "=== nsys profile finished ==="
ls -la "${NSYS_BASENAME}".* 2>/dev/null || ls -la ./*.nsys-rep 2>/dev/null || true
