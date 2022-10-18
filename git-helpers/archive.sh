#!/bin/bash
set -ue

NAME="bash-openssl-ca"

commit=$(git log --oneline -1 | cut -d' ' -f1)

git archive \
    --output=./${NAME}-${commit}.zip --format=zip \
    --prefix=${NAME}-${commit}/ HEAD
