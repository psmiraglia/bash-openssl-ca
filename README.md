# OpenSSL CA

Init the CA structure

~~~
$ ./helpers/init-ca.sh -d TestCA
~~~

Generate the CA keypair

~~~
$ ./bin/generate-ca-certificate.sh -d TestCA -o ACME -c "Root CA"
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
│   ├── ca.crt      <-- CA certificate
│   ├── ca.crt.txt
│   ├── ca.key      <-- CA private key
│   ├── ca.key.pin
│   ├── ca.p12
│   └── ca.p12.pin
├── certs
│   └── 01.pem      <-- Issued certificate
├── crl
├── crlnumber
├── index.txt
├── index.txt.attr
├── index.txt.old
├── serial
└── serial.old
~~~
