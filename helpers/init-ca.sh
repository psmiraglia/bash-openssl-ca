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
            cadir=${OPTARG}
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


# check if cadir already exists

if [ -d "${cadir}" ]; then
    _error "CA directory \"${cadir}\" already exists"
    exit 1
fi

# doit

_info "Creating directories"
mkdir -pv ${cadir}/{certs,crl,ca,config}

cadir=$(cd ${cadir} && pwd)
echo ${cadir}

pushd ${cadir} > /dev/null
    echo "$(openssl rand -hex 4)00000001" > serial
    echo "$(openssl rand -hex 4)00000001" > crlnumber
    touch index.txt
    cat <<EOF > ${cadir}/config/openssl.conf
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

[ req ]
default_bits = 3072
default_md = sha256
distinguished_name = req_dn
encrypt_key = yes
prompt = no
x509_extensions = v3_ext

[ req_dn ]
CN = %TO-BE-SET%
O = %TO-BE-SET%
OU = Certification Authority

[ v3_ext ]
basicConstraints = critical,CA:TRUE
crlDistributionPoints = cdp
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash

[ cdp ]
fullname = URI:%TO-BE-SET%
EOF
popd > /dev/null

_info "Done"
ls -l ${cadir}

exit 0
