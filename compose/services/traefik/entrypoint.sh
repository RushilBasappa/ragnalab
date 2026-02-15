#!/bin/sh
set -e

# Create traefik config directory if it doesn't exist
mkdir -p /etc/traefik

# Generate traefik.yml with EAB credentials from environment variables
cat > /etc/traefik/traefik-generated.yml <<EOF
global:
  sendAnonymousUsage: false

log:
  level: INFO

api:
  dashboard: true

ping: {}

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https

  websecure:
    address: ":443"
    http:
      tls:
        certResolver: zerossl
        domains:
          - main: "ragnalab.xyz"
            sans:
              - "*.ragnalab.xyz"

certificatesResolvers:
  zerossl:
    acme:
      email: rushil.basappa@gmail.com
      storage: /acme/acme-zerossl.json
      caServer: https://acme.zerossl.com/v2/DV90
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "8.8.8.8:53"
        delayBeforeCheck: 10
      eab:
        kid: ${ZEROSSL_EAB_KID}
        hmacEncoded: ${ZEROSSL_EAB_HMAC}

  letsencrypt:
    acme:
      email: rushil.basappa@gmail.com
      storage: /acme/acme-letsencrypt.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "8.8.8.8:53"
        delayBeforeCheck: 10

providers:
  docker:
    endpoint: "tcp://socket-proxy:2375"
    exposedByDefault: false
    network: traefik_public
EOF

# Start Traefik with the generated config
exec traefik --configFile=/etc/traefik/traefik-generated.yml
