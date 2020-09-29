#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

usage() {
    local prog="$( basename "$0" )"
    >&2 echo "
Usage: ${prog} <file>

  Search <file> under wishwms's script directory and ask to run.

e.g.
    1. Use absolute path
      ${prog} /production/wishwms/current/wishwms/.../example.py

    2. Use relative path (trigger search)
      ${prog} wishwms/script/oneoff/epc/mkl-1000/main.py
      ${prog} infra/ensure_index_consistency.py --env=prod
"
}

list_candidates() {
    while IFS= read -r -d '' filename; do
        echo "${filename}"
    done < <( find /production/wishwms/current/wishwms/script -type f -print0 | grep -izZ "$1" )
}

run_script() {
    local filename="$1"
    shift
    local options="$*"

    if ! echo "${options}" | grep -q "\-\-env="; then
        options="${options} --env=be_testing"
    fi

    echo "====== [ RUN ] ======"
    echo "Script : ${filename}"
    echo "Options: ${options}"
    echo

    sudo -u nobody \
        CL_HOME=/production/wishwms/current \
        PYTHONPATH=/production/wishwms/current \
        /production/wishwms/persistent/virtualenv/bin/python \
        "${filename}" ${options}
}

main() {
    local filename="${1:-notset}"

    if [[ "${filename}" == "notset" ]]; then
        usage
        exit 1
    fi
    shift

    local candidate
    for candidate in $( list_candidates "${filename}" ); do
        read -p ">> Run ${candidate}? (Y/n) /> " confirmed
        if [[ "${confirmed}" == "Y" || "${confirmed}" == "y" ]]; then
            run_script "${candidate}" $*
            break
        fi
    done
}

main "$@"
