# OpenSSL CA

Init the CA structure

~~~
$ ./helpers/init-ca.sh -d TestCA
~~~

Adapt the configuration of OpenSSL according to your needs

~~~
$ cd TestCA/config
$ editor openssl.conf
~~~

Generate the CA keypair

~~~
$ ./bin/generate-ca-certificate.sh -d TestCA
~~~

Issue a certificate from a CSR

~~~
$ ./bin/issue-certificate.sh -d TestCA -c TestCSR/csr.pem -e ext_files/webserver.txt
~~~

Final structure

~~~
$ tree TestCA
TestCA
├── ca
│   ├── ca.crt                <-- CA certificate
│   ├── ca.crt.txt
│   ├── ca.csr
│   ├── ca.csr.txt
│   ├── ca.key                <-- CA private key (encrypted)
│   ├── ca.key.pin            <-- CA private key (passphrase)
│   ├── ca.p12
│   └── ca.p12.pin
├── certs
│   └── D644B41300000001.pem  <-- Issued certificate
├── config
│   └── openssl.conf
├── crl
├── crlnumber
├── index.txt
├── index.txt.attr
├── index.txt.old
├── serial
└── serial.old
~~~
