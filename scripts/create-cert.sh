#!/bin/bash
# Create a self-signed code-signing certificate for local EyeBreak builds.
#
# Adapted from the peer Pester project. The certificate is self-signed, lives in
# the login keychain, and is trusted for code signing by the current user only.
# It is never distributed.
#
# EyeBreak needs a stable signature more than most apps. macOS ties Accessibility
# and Screen Recording grants to the code signature. An ad-hoc signature ("-")
# changes its cdhash on every build, so every rebuild would ask for those
# permissions again. A stable certificate keeps the grants across rebuilds.
#
# Run this script. It tries the automated route first. If that fails it prints
# instructions for the Keychain Access Certificate Assistant instead.

set -uo pipefail

CN="EyeBreak Local Signing"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Transport password for the PKCS#12 bundle only. The bundle lives in $WORK and
# is deleted on exit; nothing in the keychain is protected by this.
P12PASS="eyebreak-transport"

have_identity() {
    security find-identity -v -p codesigning 2>/dev/null | grep -qF "$CN"
}

# A certificate can exist without being a valid identity: untrusted, expired, or
# missing its private key. Detect that separately so the script never creates a
# second certificate with the same common name.
have_certificate() {
    security find-certificate -c "$CN" "$KEYCHAIN" >/dev/null 2>&1
}

report_success() {
    echo
    echo "Code-signing identity is present:"
    security find-identity -v -p codesigning | grep -F "$CN"
    echo
    echo "scripts/dev-install.sh uses this common name automatically."
    echo
    echo "Expires:"
    security find-certificate -c "$CN" -p "$KEYCHAIN" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | sed 's/^notAfter=/    /'
}

manual_instructions() {
    cat <<'INSTRUCTIONS'

Automated creation did not work. Create the certificate by hand instead.

 1. Open Keychain Access (/System/Applications/Utilities/Keychain Access.app).
 2. Menu: Keychain Access > Certificate Assistant > Create a Certificate...
 3. Name:             EyeBreak Local Signing
    Identity Type:    Self Signed Root
    Certificate Type: Code Signing
    Leave "Let me override defaults" unchecked.
 4. Click Create, then Continue past the self-signed warning, then Done.
 5. Run this script again to verify the result.

INSTRUCTIONS
}

if have_identity; then
    echo "A code-signing identity named \"$CN\" already exists."
    report_success
    exit 0
fi

if have_certificate; then
    cat <<CERT_EXISTS
A certificate named "$CN" is already in the login keychain, but it is not a
valid signing identity. Creating a second one would make the name ambiguous,
so this script stops here.

The usual cause is missing code-signing trust. Fix it with:

    security find-certificate -c "$CN" -p "$KEYCHAIN" > cert.pem
    security add-trusted-cert -p codeSign -k "$KEYCHAIN" cert.pem

If the certificate has expired instead, delete it in Keychain Access, then run
this script again.

Current state:
CERT_EXISTS
    # The basic policy, not -p codesigning: the code-signing policy filter hides
    # the untrusted certificate we are trying to report on.
    security find-identity | grep -F "$CN" || true
    exit 1
fi

echo "Creating a self-signed code-signing certificate: $CN"
echo

# An X.509 extension set that makes the certificate usable for code signing.
# codesign requires the codeSigning extended key usage; Security.framework
# requires basicConstraints CA:true for a self-signed root.
cat > "$WORK/ext.cnf" <<EXT
[ req ]
distinguished_name = dn
prompt = no
x509_extensions = codesign

[ dn ]
CN = $CN

[ codesign ]
basicConstraints = critical,CA:true
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
subjectKeyIdentifier = hash
EXT

if ! openssl req -x509 -newkey rsa:2048 -sha256 -days 7300 -nodes \
        -config "$WORK/ext.cnf" \
        -keyout "$WORK/key.pem" -out "$WORK/cert.pem" 2>"$WORK/openssl.log"; then
    echo "openssl failed:"
    cat "$WORK/openssl.log"
    manual_instructions
    exit 1
fi

# Bundle key and certificate so the keychain stores them as one identity.
#
# The PBE algorithms are not optional. OpenSSL 3 defaults to AES-256-CBC with a
# PBKDF2 MAC, which Security.framework cannot read: `security import` fails with
# "MAC verification failed during PKCS12 import (wrong password?)". The SHA1/3DES
# algorithms below are what macOS understands. An empty password fails the same
# way, so the bundle carries a throwaway one; it never leaves this script.
if ! openssl pkcs12 -export -inkey "$WORK/key.pem" -in "$WORK/cert.pem" \
        -name "$CN" \
        -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1 \
        -passout "pass:$P12PASS" -out "$WORK/identity.p12" 2>"$WORK/p12.log"; then
    echo "openssl pkcs12 failed:"
    cat "$WORK/p12.log"
    manual_instructions
    exit 1
fi

echo "Importing into the login keychain."
echo "macOS may ask for your login password. Choosing \"Always Allow\" avoids a"
echo "prompt on every build."
echo

# -T grants codesign access to the private key without a prompt per signature.
if ! security import "$WORK/identity.p12" -k "$KEYCHAIN" -P "$P12PASS" \
        -T /usr/bin/codesign -T /usr/bin/security; then
    echo "Import failed."
    manual_instructions
    exit 1
fi

echo
echo "Marking the certificate as trusted for code signing."
echo "macOS will ask for your login password to change trust settings."
echo

# User-domain trust. This does not affect any other account on the machine.
if ! security add-trusted-cert -p codeSign -k "$KEYCHAIN" "$WORK/cert.pem"; then
    echo "Setting trust failed."
    manual_instructions
    exit 1
fi

# Let codesign use the key without an interactive prompt on each build.
# Do not pass -k: an empty password fails silently on a keychain that has one,
# and the failure only shows up later as an authorization dialog per build.
# Without -k, macOS asks for the keychain password once, here.
if ! security set-key-partition-list -S apple-tool:,apple:,codesign: \
        "$KEYCHAIN" >/dev/null; then
    echo
    echo "Warning: could not set the key partition list. Signing still works,"
    echo "but macOS may ask for authorization on every build. To retry:"
    echo "    security set-key-partition-list -S apple-tool:,apple:,codesign: \\"
    echo "        \"$KEYCHAIN\""
fi

if have_identity; then
    report_success
    exit 0
fi

echo "The certificate was imported but does not appear as a valid signing identity."
security find-identity -v -p codesigning
manual_instructions
exit 1
