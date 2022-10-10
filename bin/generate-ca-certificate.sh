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
    echo "Usage: ${0} -d <cadir> [-h]" 1>&2
}


exit_abnormal() {
    usage
    exit 1
}

# parse input arguments

cadir=""
while getopts ":d:h" opt; do
    case "${opt}" in
        d)
            cadir=$(cd ${OPTARG} && pwd)
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

if [ -z "${cadir}" ]; then
    exit_abnormal
fi

if [ ! -d "${cadir}/ca" ]; then
    _error "CA directory \"${cadir}/ca\" does not exist"
    exit 1
fi

openssl_conf=${cadir}/config/openssl.conf
if [ $(grep -ic "%TO-BE-SET%" ${openssl_conf}) -gt 0 ]; then
    _error "OpenSSL configuration still contains placeholders (${openssl_conf})"
    exit 1
fi

pushd ${cadir}/ca > /dev/null
    # files
    key_file="ca.key"
    key_pin_file="${key_file}.pin"
    csr_file="ca.csr"
    csr_dump_file="${csr_file}.txt"
    crt_file="ca.crt"
    crt_dump_file="${crt_file}.txt"
    p12_file="ca.p12"
    p12_pin_file="${p12_file}.pin"
    
    # check if keypair already exists
    for f in ${key_file} ${key_pin_file} ${crt_file} ${p12_file} ${p12_pin_file}; do
        if [ -f ${f} ]; then
            _error "File already exists: ${f}"
            exit 0
        fi
    done

    # generate openssl configuration

    # generate privkey
    _info "Generate privkey (${key_file}/${key_pin_file})"
    openssl rand -hex -out ${key_pin_file} 32
    openssl genrsa -des3 -out ${key_file} -passout file:${key_pin_file} 3072

    # generate csr
    _info "Generate CSR (${csr_file})"
    openssl req -new -config ${openssl_conf} \
        -key ${key_file} -passin file:${key_pin_file} \
        -out ${csr_file}
    _info "Dump CSR for easy reading (${csr_dump_file})"
    openssl req -in  ${csr_file} -text -out ${csr_dump_file}

    # issue certificate
    _info "Issue certificate (${crt_file})"
    days=3650  # 10 years
    openssl x509 -req -in ${csr_file} \
        -signkey ${key_file} -passin file:${key_pin_file} -sha256 \
        -days ${days} -extfile ${openssl_conf} -extensions v3_ext \
        -out ${crt_file}

    # dump certificate for easy reading
    _info "Dump certificate for easy reading (${crt_dump_file})"
    openssl x509 -noout -text -in ${crt_file} -out ${crt_dump_file}

    # generate PKCS12
    _info "Create PKCS12 (${p12_file})"
    openssl rand -hex -out ${p12_pin_file} 32
    openssl pkcs12 \
        -export -out ${p12_file} -passout file:${p12_pin_file} \
        -inkey ${key_file} -passin file:${key_pin_file} -in ${crt_file}

popd > /dev/null

# vim: ft=sh
