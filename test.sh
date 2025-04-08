#!/bin/bash

cd $(dirname $0)

run_tests () {
    if grep -q "module+ test" "$1"; then
        echo "testing $1"
        raco test "$1"
    fi
}

export -f run_tests
find . -name "*.rkt" -exec bash -c 'run_tests "${1}"' -- {} \;