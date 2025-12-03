#!/usr/bin/env bash

KEYCLOAK_HOST=keycloak
KEYCLOAK_PORT=8080

echo "Waiting for Keycloak at $KEYCLOAK_HOST:$KEYCLOAK_PORT ..."

for i in {1..200}; do
    if (echo > /dev/tcp/$KEYCLOAK_HOST/$KEYCLOAK_PORT) >/dev/null 2>&1; then
        RESPONSE=$(exec 3<>/dev/tcp/$KEYCLOAK_HOST/$KEYCLOAK_PORT; printf "GET /health/ready HTTP/1.0\r\n\r\n" >&3; cat <&3)

        if echo "$RESPONSE" | grep -q "200 OK"; then
            echo "Keycloak is ready!"
            exit 0
        fi
    fi

    echo "Keycloak not ready yet... ($i/200)"
    sleep 2
done

echo "Keycloak failed to start in time!"
exit 1
