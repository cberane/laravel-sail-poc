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
mkdir -p docker/nginx/certificates

echo "entering docker/nginx/certificates"
pushd docker/nginx/certificates || exit

# Generate a private key
if [ ! -f development-ca.key ]; then
    echo "Generating private key development-ca.key"
    openssl genrsa -out development-ca.key 2048
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
    openssl genrsa -out server.key 2048
else
    echo "server.key already exists"
fi

# Generate a certificate signing request for the server
if [ ! -f server.csr ]; then
    echo "Generating certificate signing request server.csr"
    openssl req -new -key server.key -out server.csr \
        -subj "/C=DE/ST=NRW/L=Local/O=MyOwn/OU=Development/CN=$APP_DOMAIN"
else
    echo "server.csr already exists"
fi

# Generate the server certificate using the CA
if [ ! -f server.crt ]; then
    echo "Generating server certificate server.crt"
    openssl x509 -req -in server.csr -CA development-ca.crt -CAkey development-ca.key -CAcreateserial \
        -out server.crt -days 3650 -sha256
else
    echo "server.crt already exists"
fi

popd || exit
