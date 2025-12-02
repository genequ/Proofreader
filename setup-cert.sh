#!/bin/bash
set -e

CERT_NAME="ProofreaderDev"
KEYCHAIN="login.keychain-db"

CERT_NAME="ProofreaderDev"
KEYCHAIN="login.keychain-db"
BACKUP_FILE="ProofreaderDev.p12"

# 1. Clean up existing certificates to avoid ambiguity
echo "Cleaning up existing '$CERT_NAME' certificates..."
# Get list of SHA-1 hashes for certificates with the name
HASHES=$(security find-certificate -a -c "$CERT_NAME" -Z | grep "SHA-1" | awk '{print $NF}')
if [ -n "$HASHES" ]; then
    echo "$HASHES" | while read -r HASH; do
        echo "Deleting certificate with hash: $HASH"
        security delete-certificate -Z "$HASH" || true
    done
else
    echo "No existing certificates found."
fi

# 2. Generate or use existing p12
if [ -f "$BACKUP_FILE" ]; then
    echo "Found existing backup '$BACKUP_FILE'. Re-importing it."
else
    echo "Generating self-signed certificate for '$CERT_NAME'..."

    # Create a temporary directory for intermediate files
    TMP_DIR=$(mktemp -d)
    
    # Create OpenSSL config for code signing
    cat > "$TMP_DIR/cert.cnf" << EOF
[ req ]
default_bits        = 2048
distinguished_name  = req_distinguished_name
x509_extensions     = v3_req
prompt              = no

[ req_distinguished_name ]
CN                  = $CERT_NAME

[ v3_req ]
basicConstraints    = critical, CA:FALSE
keyUsage            = critical, digitalSignature
extendedKeyUsage    = critical, codeSigning
EOF

    # Generate key and certificate
    openssl req -x509 -newkey rsa:2048 -keyout "$TMP_DIR/key.pem" -out "$TMP_DIR/cert.pem" -days 3650 -nodes -config "$TMP_DIR/cert.cnf"

    # Package into p12
    # Use -legacy for compatibility with macOS security tool if using OpenSSL 3+
    openssl pkcs12 -export -legacy -in "$TMP_DIR/cert.pem" -inkey "$TMP_DIR/key.pem" -out "$BACKUP_FILE" -passout pass:temp

    # Clean up temp dir
    rm -rf "$TMP_DIR"
    
    echo "✅ Certificate saved to '$BACKUP_FILE' (Backup)"
fi

echo "Importing certificate into keychain..."
# Import into keychain
# -P temp: password for p12
# -T /usr/bin/codesign: allow codesign to access this key
security import "$BACKUP_FILE" -k "$HOME/Library/Keychains/$KEYCHAIN" -P temp -T /usr/bin/codesign

echo "Trusting certificate..."
# Add to trust settings
# Extract the cert from p12 to trust it (security add-trusted-cert needs a pem or der)
# We can extract it back out or just rely on the fact that we just imported it.
# Actually, add-trusted-cert needs a file.
openssl pkcs12 -in "$BACKUP_FILE" -nokeys -out cert_public.pem -passin pass:temp -legacy
security add-trusted-cert -d -r trustRoot -k "$HOME/Library/Keychains/$KEYCHAIN" cert_public.pem
rm cert_public.pem

echo "✅ Certificate '$CERT_NAME' created and imported successfully."
echo "You may be prompted for your password to modify the keychain."
