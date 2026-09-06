#!/usr/bin/env bash
set -euxo pipefail

if [ "${target_platform:-}" = "linux-aarch64" ] && [ "${blas_impl:-}" != "nvpl" ]; then
  export OPENBLAS_CORETYPE="${OPENBLAS_CORETYPE:-ARMV8}"
fi

cmake -S . -B build -G Ninja \
  ${CMAKE_ARGS:-} \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DCMAKE_CXX_SCAN_FOR_MODULES=OFF \
  -DHDF5_ROOT="${PREFIX}" \
  -DNRGLJUBLJANA_USE_SYSTEM_DEPS=ON \
  -DNRGLJUBLJANA_ENABLE_MATHEMATICA=OFF \
  -DBuild_Tests=OFF \
  -DMPI_C_COMPILER="${PREFIX}/bin/mpicc" \
  -DMPI_CXX_COMPILER="${PREFIX}/bin/mpicxx" \
  -DMPIEXEC_EXECUTABLE="${PREFIX}/bin/mpiexec"

cmake --build build --parallel "${CPU_COUNT:-1}"

cmake --install build

# Let Conda manage PATH; invoke the original launcher in its resource directory.
cat > "${PREFIX}/bin/nrginit" <<'NRGINIT_EOF'
#!/bin/bash
exec "$(dirname "${BASH_SOURCE[0]}")/../nrginit/nrginit" "$@"
NRGINIT_EOF
chmod 755 "${PREFIX}/bin/nrginit"

mkdir -p "${PREFIX}/etc/conda/activate.d" "${PREFIX}/etc/conda/deactivate.d"

cat > "${PREFIX}/etc/conda/activate.d/nrgljubljana.sh" <<'ACTIVATE_EOF'
export NRGLJUBLJANA_ROOT="${CONDA_PREFIX}"
ACTIVATE_EOF

cat > "${PREFIX}/etc/conda/deactivate.d/nrgljubljana.sh" <<'DEACTIVATE_EOF'
unset NRGLJUBLJANA_ROOT NRGLJUBLJANA_CONDA_PATH_BACKUP
DEACTIVATE_EOF
