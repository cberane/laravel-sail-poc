#!/bin/bash

# halt on any error
set -e

# load .env file
if [ ! -f .env ]; then
  echo "No .env file found. Please copy the .env.example file and adjust it to your needs."
  exit 1
fi

set -o allexport; source .env; set +o allexport

if [ -z "$APP_DOMAIN" ]; then
  echo "Please set the APP_DOMAIN variable in the .env file."
  exit 1
fi

echo "Preparing certificates for the development environment"
mkdir -p nginx/certs

echo "entering nginx/certs"
if ! pushd nginx/certs; then
    echo "Failed to enter nginx/certs directory" >&2
    exit 1
fi

# Generate OpenSSL configuration file dynamically
cat > openssl.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = DE
ST = RLP
L = Local
O = Development
OU = Laravel
CN = CA $APP_DOMAIN

[v3_ca]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
basicConstraints = critical,CA:TRUE
keyUsage = critical, keyCertSign, cRLSign

[v3_req]
subjectAltName = @alt_names
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[alt_names]
DNS.1 = $APP_DOMAIN
DNS.2 = *.$APP_DOMAIN
EOF

# Generate a private key
if [ ! -f development-ca.key ]; then
    echo "Generating private key development-ca.key"
    openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out development-ca.key
else
    echo "development-ca.key already exists"
fi

# Generate a self-signed certificate, valid for 10 years
if [ ! -f development-ca.crt ]; then
    echo "Generating self-signed certificate development-ca.crt"
    openssl req -x509 -new -nodes -key development-ca.key -sha256 -days 3650 -out development-ca.crt \
        -subj "/C=DE/ST=RLP/L=Local/O=Development/OU=Laravel/CN=CA $APP_DOMAIN"
else
    echo "development-ca.crt already exists"
fi

# Generate a private key for the server
if [ ! -f server.key ]; then
    echo "Generating private key server.key"
    openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out server.key
else
    echo "server.key already exists"
fi

echo "Generating certificate signing request server.csr"
openssl req -new -key server.key -out server.csr -config openssl.cnf

echo "Generating server certificate server.crt"
openssl x509 -req -in server.csr -CA development-ca.crt -CAkey development-ca.key -CAcreateserial \
    -out server.crt -days 3650 -sha256 -extfile openssl.cnf -extensions v3_req

echo "creating chained server certificate server.chained.crt"
cat server.crt development-ca.crt > server.chained.crt

echo "Cleaning up"
rm openssl.cnf server.csr

popd || exit

echo "entering nginx"
if ! pushd nginx; then
    echo "Failed to enter nginx directory" >&2
    exit 1
fi

echo "Creating default.conf for nginx"
cat > default.conf <<EOF
server {
    listen                  443 ssl;
    listen                  [::]:443 ssl;
    server_name             $APP_DOMAIN;

    ssl_certificate         /etc/nginx/certs/server.chained.crt;
    ssl_certificate_key     /etc/nginx/certs/server.key;

    location / {
        # proxy to the laravel base app
        proxy_pass "http://laravel.test:${APP_PORT:-80}/";
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
EOF

popd || exit
