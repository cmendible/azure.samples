#! /bin/sh
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 3650 -key ca.key -subj '/CN=*.westeurope.cloudapp.azure.com' -out ca.crt
openssl req -newkey rsa:4096 -nodes -keyout server.key -subj '/CN=*.westeurope.cloudapp.azure.com' -out server.csr
openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt
openssl pkcs12 -export -out server.pfx -inkey server.key -in server.crt
rm server.csr
rm server.crt
rm server.key
rm ca.srl
rm ca.key