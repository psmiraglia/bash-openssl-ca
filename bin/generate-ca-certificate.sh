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
    echo "Usage: ${0} -d <cadir> -o <organization> -c <common name> [-h]" 1>&2
}


exit_abnormal() {
    usage
    exit 1
}

# parse input arguments

cadir=""
organization=""
cn=""
while getopts ":d:o:c:h" opt; do
    case "${opt}" in
        d)
            cadir=${OPTARG}
            ;;
        o)
            organization=${OPTARG}
            ;;
        c)
            cn=${OPTARG}
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

if [ -z "${cadir}" ] || [ -z "${organization}" ] || [ -z "${cn}" ]; then
    exit_abnormal
fi

if [ ! -d "${cadir}/ca" ]; then
    _error "CA directory \"${cadir}/ca\" does not exist"
    exit 1
fi

pushd ${cadir}/ca > /dev/null
    # files
    key_file="ca.key"
    key_pin_file="${key_file}.pin"
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
    openssl_conf=$(mktemp)
    cat <<EOF > ${openssl_conf}
[ req ]
distinguished_name = req_dn
x509_extensions = v3_ext

[ req_dn ]

[ v3_ext ]
basicConstraints = CA:TRUE
certificatePolicies = @polsect
keyUsage = keyCertSign
subjectKeyIdentifier = hash

[ polsect ]
policyIdentifier = 1.2.3.4.1455.67.89.5
userNotice.1 = @notice

[ notice ]
explicitText = "The CA is an internal resource. Certificates that are issued by this CA are for internal use only."
organization = "${organization}"
noticeNumbers = 1
EOF

    # generate keypair
    key_type="rsa:3072"
    days=3650  # 10 years
    subject="/O=${organization}/CN=${cn}"
    _info "Creating ${key_type} keypair (${key_file}/${crt_file})"
    openssl rand -hex -out ${key_pin_file} 32
    openssl req -new -config ${openssl_conf} \
        -newkey ${key_type} -passout file:${key_pin_file} -keyout ${key_file} \
        -x509 -sha256 -days ${days} -out ${crt_file} \
        -subj "${subject}"

    # dump certificate for easy reading
    _info "Dumping certificate (${crt_dump_file})"
    openssl x509 -noout -text -in ${crt_file} -out ${crt_dump_file}

    # generate PKCS12
    _info "Creating PKCS12 (${p12_file})"
    openssl rand -hex -out ${p12_pin_file} 32
    openssl pkcs12 \
        -export -out ${p12_file} -passout file:${p12_pin_file} \
        -inkey ${key_file} -passin file:${key_pin_file} -in ${crt_file} -name "${subject}"

    # cleanup
    rm ${openssl_conf}
popd > /dev/null

# vim: ft=sh
