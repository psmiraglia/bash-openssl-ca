#!/bin/bash

# Copyright 2022 Paolo Smiraglia <paolo.smiraglia@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -ue

# logging helpers

_log() {
    lvl=${1}
    msg=${2}
    echo "[${lvl}] ${msg}"
}

_info() {
    _log "INFO " "${1}"
}

_error() {
    _log "ERROR" "${1}"
}

# functions

usage() {
    echo "Usage: ${0} -d <cadir> -c <csr_file> -e <ext_file> [-h]" 1>&2
}


exit_abnormal() {
    usage
    exit 1
}

# parse input arguments

cadir=""
csr_file=""
ext_file=""
while getopts ":d:c:e:h" opt; do
    case "${opt}" in
        d)
            cadir=${OPTARG}
            ;;
        c)
            csr_file=${OPTARG}
            ;;
        e)
            ext_file=${OPTARG}
            ;;
        h)
            usage
            exit 0
            ;;
        :)
            _error "Option \"-${OPTARG}\" requires an argument"
            exit_abnormal
            ;;
        *)
            exit_abnormal
            ;;
    esac
done

if [ -z "${cadir}" ] || [ -z "${csr_file}" ] || [ -z "${ext_file}" ]; then
    exit_abnormal
fi

if [ ! -d "${cadir}" ]; then
    _error "CA directory \"${cadir}/ca\" does not exist"
    exit 1
fi

# generate openssl conf
openssl_conf=$(mktemp)
cat <<EOF > ${openssl_conf}
dir = ${cadir}

[ ca ]
default_ca             = CA_default

[ CA_default ]
serial                 = \$dir/serial
database               = \$dir/index.txt
new_certs_dir          = \$dir/certs
certificate            = \$dir/ca/ca.crt
private_key            = \$dir/ca/ca.key
crldir                 = \$dir/crl
crlnumber              = \$dir/crlnumber
crl                    = \$crldir/crl.pem
default_days           = 720
default_crl_days       = 30
default_md             = sha256
policy                 = policy_match

[ policy_match ]
organizationName       = supplied
organizationalUnitName = supplied
commonName             = supplied
EOF

# issue certificate
openssl ca -config ${openssl_conf} -passin file:${cadir}/ca/ca.key.pin \
    -extfile "${ext_file}" -batch -infiles "${csr_file}"

# cleanup
rm -iv ${openssl_conf}

# vim: ft=sh
