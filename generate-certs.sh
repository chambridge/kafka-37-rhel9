#!/bin/bash

# Script to generate TLS certificates for Kafka

# Configuration
OUTPUT_DIR="certs"
CA_KEY="ca.key"
CA_CERT="ca.crt"
SERVER_KEY="kafka-server.key"
SERVER_CERT="kafka-server.crt"
SERVER_CSR="kafka-server.csr"
SERVER_P12="kafka-server.p12"
SERVER_KEYSTORE="kafka-server.keystore.jks"
CLIENT_KEY="client.key"
CLIENT_CERT="client.crt"
CLIENT_CSR="client.csr"
TRUSTSTORE="kafka.truststore.jks"
PASSWORD="yourpassword" # Change this
DAYS_VALID=365

# Check for dependencies
check_dependency() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: $1 is required but not installed."
        if [ "$(uname)" = "Darwin" ]; then 
            echo "On macOS, install via: brew install $2"
        elif [ "$(uname)" = "Linux" ]; then
            echo "On RHEL, install via: sudo dnf install $2"
        fi
        exit 1
    fi
}

echo "Checking dependencies ..."
check_dependency "openssl" "openssl"
check_dependency "keytool" "java-11-openjdk"

# Create output dir
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR" || exit 1

# Generate CA
if [ ! -f "$CA_CERT" ]; then
    echo "Generating CA certificate ..."
    openssl genrsa -out "$CA_KEY" 2048
    openssl req -new -x509 -days "$DAYS_VALID" -key "$CA_KEY" -out "$CA_CERT" \
        -subj "/CN=MyKafkaCA" -nodes || {
        echo "Failed to generate CA"
        exit 1
    }
else
    echo "CA certificate already exists, skipping ..."
fi

# Generate Server Cert
echo "Generating server certificate ..."
openssl genrsa -out "$SERVER_KEY" 2048
openssl req -new -key "$SERVER_KEY" -out "$SERVER_CSR" \
    -subj "/CN=localhost" -nodes
openssl x509 -req -in "$SERVER_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" \
    -CAcreateserial -out "$SERVER_CERT" -days "$DAYS_VALID" || {
        echo "Failed to generate server certificate"
        exit 1
    }

# Convert Server Cert to PKCS12 then JKS
echo "Converting server cert to JKS ..."
openssl pkcs12 -export -in "$SERVER_CERT" -inkey "$SERVER_KEY" \
    -out "$SERVER_P12" -name kafka -password "pass:$PASSWORD"
keytool -importkeystore -srckeystore "$SERVER_P12" -srcstoretype PKCS12 \
    -destkeystore "$SERVER_KEYSTORE" -deststoretype JKS \
    -srcstorepass "$PASSWORD" -deststorepass "$PASSWORD" -noprompt || {
        echo "Failed to create server keystore"
        exit 1
    }

# Generate Client Cert for mTLS
echo "Generating client certificate ..."
openssl genrsa -out "$CLIENT_KEY" 2048
openssl req -new -key "$CLIENT_KEY" -out "$CLIENT_CSR" \
    -subj "/CN=kafka-client" -nodes
openssl x509 -req -in "$CLIENT_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" \
    -CAcreateserial -out "$CLIENT_CERT" -days "$DAYS_VALID" || {
        echo "Failed to generate client certificate"
        exit 1
    }

# Create Truststore with CA Cert
if [ ! -f "$TRUSTSTORE" ]; then
    echo "Creating truststore ..."
    keytool -import -file "$CA_CERT" -alias ca -keystore "$TRUSTSTORE" -storepass "$PASSWORD" -noprompt || {
            echo "Failed to create truststore"
            exit 1
        }
else
    echo "Truststore already exists, skipping ..."
fi

# Clean up intermediat files
rm -f "$SERVER_CSR" "$SERVER_P12" "$CLIENT_CSR" "$CA_KEY.srl"

# Set permissions
echo "Setting permissions ..."
chmod 600 "$CA_KEY" "$CA_CERT" "$SERVER_KEY" "$SERVER_CERT" "$SERVER_KEYSTORE" \
    "$CLIENT_KEY" "$CLIENT_CERT" "$TRUSTSTORE"

echo "Certificates generated successfully in $OUTPUT_DIR:"
ls -l
