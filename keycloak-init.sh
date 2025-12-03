#!/usr/bin/env bash
set -e

# Start Keycloak in the background
echo "Starting Keycloak..."
/opt/keycloak/bin/kc.sh start-dev --http-relative-path=/auth --hostname-strict=false --http-host=0.0.0.0 &
KC_PID=$!

# Wait for Keycloak to be ready
echo "Waiting for Keycloak to start..."
while true; do
    # Using bash built-in /dev/tcp to check readiness because curl might not be available
    if (echo > /dev/tcp/localhost/8080) >/dev/null 2>&1; then
        # Connect to localhost:8080, send GET request, and check for 200 OK
        # We use HTTP/1.0 and Connection: close to ensure the connection closes
        exec 3<>/dev/tcp/localhost/8080
        echo -e "GET /auth/health/ready HTTP/1.0\r\nConnection: close\r\n\r\n" >&3
        # Read response
        RESPONSE=$(cat <&3)
        # Close fd
        exec 3<&-
        
        if echo "$RESPONSE" | grep -q "404 Not Found"; then
            echo "Keycloak is ready!"
            break
        fi
    fi
    sleep 5
    echo "Still waiting for Keycloak..."
done

echo "Keycloak is up! Running initialization..."

# Login to Keycloak admin CLI
echo "Logging into Keycloak Admin CLI..."
/opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080/auth \
  --realm master \
  --user ${KEYCLOAK_ADMIN:-admin} \
  --password ${KEYCLOAK_ADMIN_PASSWORD:-admin}

# Create Realm if it doesn't exist
if ! /opt/keycloak/bin/kcadm.sh get realms/myrealm > /dev/null 2>&1; then
    echo "Creating realm 'myrealm'..."
    /opt/keycloak/bin/kcadm.sh create realms \
      -s realm=myrealm \
      -s enabled=true
else
    echo "Realm 'myrealm' already exists."
fi

# Create Client if it doesn't exist
if ! /opt/keycloak/bin/kcadm.sh get clients -r myrealm -q clientId=fastapi-service | grep "fastapi-service" > /dev/null; then
    echo "Creating client 'fastapi-service'..."
    /opt/keycloak/bin/kcadm.sh create clients -r myrealm \
      -s clientId=fastapi-service \
      -s publicClient=false \
      -s serviceAccountsEnabled=true \
      -s directAccessGrantsEnabled=true \
      -s enabled=true \
      -s secret=my-secret \
      -s 'redirectUris=["*"]'
else
    echo "Client 'fastapi-service' already exists."
fi

# Create User if it doesn't exist
USERNAME="testuser"
PASSWORD="testpassword"

if ! /opt/keycloak/bin/kcadm.sh get users -r myrealm -q username=$USERNAME | grep "$USERNAME" > /dev/null; then
    echo "Creating user '$USERNAME'..."
    USER_ID=$(/opt/keycloak/bin/kcadm.sh create users -r myrealm \
      -s username="$USERNAME" \
      -s enabled=true \
      -i)
    
    echo "Setting password for user '$USERNAME'..."
    /opt/keycloak/bin/kcadm.sh set-password -r myrealm \
      --userid "$USER_ID" \
      -p "$PASSWORD"
    
    echo "User '$USERNAME' created."
else
    echo "User '$USERNAME' already exists."
fi

echo "Keycloak initialization completed!"
echo "Realm: myrealm"
echo "Client: fastapi-service"

# Wait for the Keycloak process to exit
wait $KC_PID
