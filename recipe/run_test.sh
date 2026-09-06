#!/bin/bash
set -e

(
    set -euo pipefail
    export CONDA_PREFIX="${PREFIX}"
    export PATH="${PREFIX}/bin:/usr/bin::/bin:/path with spaces:"
    unset NRGLJUBLJANA_ROOT NRGLJUBLJANA_CONDA_PATH_BACKUP

    before="${PATH}"
    for iteration in 1 2; do
        . "${PREFIX}/etc/conda/activate.d/nrgljubljana.sh"
        test "${PATH}" = "${before}"
        test "${NRGLJUBLJANA_ROOT}" = "${PREFIX}"
        test "${NRGLJUBLJANA_CONDA_PATH_BACKUP+x}" != x
    done
    test "$(command -v nrginit)" = "${PREFIX}/bin/nrginit"

    # Inspect the kernel input without requiring Mathematica.
    export NRG_TEST_EXPECTED_PWD="${PWD}"
    _nrg_test_math() {
        test "$*" = "-batchinput -batchoutput" || return 1
        test "${PWD}" = "${NRG_TEST_EXPECTED_PWD}" || return 1
        cat
    }
    export -f _nrg_test_math

    nrgdir="$(cd "${PREFIX}/nrginit" && pwd -P)"
    expected=$(printf 'NRGDIR="%s";\nGet["%s/nrginit.m"];\n' "${nrgdir}" "${nrgdir}")
    test "$(nrginit _nrg_test_math)" = "${expected}"

    # Conda has already removed PREFIX/bin; preserve that and later PATH edits.
    export PATH="/user-added:/usr/bin::/bin:"
    before="${PATH}"
    export NRGLJUBLJANA_CONDA_PATH_BACKUP="${PREFIX}/bin:/obsolete"
    . "${PREFIX}/etc/conda/deactivate.d/nrgljubljana.sh"
    test "${PATH}" = "${before}"
    test "${NRGLJUBLJANA_ROOT+x}" != x
    test "${NRGLJUBLJANA_CONDA_PATH_BACKUP+x}" != x

    unset CONDA_PREFIX
    test "$("${PREFIX}/bin/nrginit" _nrg_test_math)" = "${expected}"

    _nrg_test_failure() { return 42; }
    export -f _nrg_test_failure
    status=0
    "${PREFIX}/bin/nrginit" _nrg_test_failure >/dev/null 2>&1 || status=$?
    test "${status}" -eq 42
)
