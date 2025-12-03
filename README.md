# FastAPI MongoDB Microservice with Keycloak Authentication

This project demonstrates a microservice architecture using FastAPI, MongoDB, and Keycloak for authentication.

## Features
- **FastAPI**: High-performance web framework for building APIs.
- **MongoDB**: NoSQL database for storing application data.
- **Keycloak**: Identity and Access Management (IAM) for securing the API.
- **Docker**: Containerized environment for easy setup and deployment.

## Prerequisites
- Docker
- Docker Compose

## Getting Started

1. **Clone the repository** (if you haven't already).

2. **Start the services**:
   ```bash
   docker-compose up --build
   ```
   This command will start:
   - **MongoDB**: Database service.
   - **Keycloak**: IAM service (initialized with a realm, client, and user).
   - **Server**: The FastAPI application.

   *Note: Keycloak may take a minute or two to fully start and initialize.*

## Keycloak Configuration
The project automatically initializes Keycloak with the following settings:
- **Admin Console**: `http://localhost:8080/auth/admin`
  - Username: `admin`
  - Password: `admin`
- **Realm**: `myrealm`
- **Client**: `fastapi-service`
  - Client Secret: `my-secret`
- **Test User**:
  - Username: `testuser`
  - Password: `testpassword`

## Testing the API

### 1. Get an Access Token
You can obtain an access token using the Client Credentials grant type (for service-to-service communication) or Password grant type.

**Using Client Credentials:**
```bash
curl -X POST 'http://localhost:8080/auth/realms/myrealm/protocol/openid-connect/token' \
 --header 'Content-Type: application/x-www-form-urlencoded' \
 --data-urlencode 'grant_type=client_credentials' \
 --data-urlencode 'client_id=fastapi-service' \
 --data-urlencode 'client_secret=my-secret'
```

**Using Password Grant:**
```bash
curl -X POST 'http://localhost:8080/auth/realms/myrealm/protocol/openid-connect/token' \
 --header 'Content-Type: application/x-www-form-urlencoded' \
 --data-urlencode 'grant_type=password' \
 --data-urlencode 'client_id=fastapi-service' \
 --data-urlencode 'client_secret=my-secret' \
 --data-urlencode 'username=testuser' \
 --data-urlencode 'password=testpassword'
```

### 2. Call the Protected API
Copy the `access_token` from the response above and use it to call the API.

```bash
curl -X POST 'http://localhost:8888/api/sample-resource-app/v1/sample-resource' \
  --header 'Authorization: Bearer <YOUR_ACCESS_TOKEN>' \
  --header 'Content-Type: application/json' \
  --data '{
    "name": "test-resource"
  }'
```

### VS Code REST Client
If you use the REST Client extension for VS Code, you can use the provided `.http` files:
- `token.http`: To generate a token.
- `request.http`: To make API requests (remember to update the Bearer token manually).

## Project Structure
- `app/`: FastAPI application code.
- `tests/`: Pytest tests.
- `docker-compose.yml`: Docker services configuration.
- `keycloak-init.sh`: Script to initialize Keycloak configuration on startup.
