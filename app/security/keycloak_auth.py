import os
from typing import Dict, Any
from fastapi import Depends, HTTPException, status, Request
from jose import jwt
import requests
from dotenv import load_dotenv
from functools import lru_cache

load_dotenv()

KEYCLOAK_URL="http://keycloak:8080/auth"
KEYCLOAK_REALM="myrealm"
CLIENT_ID="fastapi-service"
ALGO="RS256"

#KEYCLOAK_URL = os.environ.get("KEYCLOAK_URL")
#REALM = os.environ.get("KEYCLOAK_REALM")
#CLIENT_ID = os.environ.get("KEYCLOAK_CLIENT_ID")
#ALGO = os.environ.get("KEYCLOAK_ALGO", "RS256")

JWKS_URL = f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}/protocol/openid-connect/certs"
print("********" + JWKS_URL)

#@lru_cache()
def get_jwks() -> Dict[str, Any]:
    """Cached fetch of Keycloak JWKS public keys."""
    resp = requests.get(JWKS_URL)
    resp.raise_for_status()
    #print("********" + resp.json())
    return resp.json()


def get_public_key(kid: str):
    jwks = get_jwks()
    for key in jwks["keys"]:
        if key["kid"] == kid:
            return key
    return None


def verify_access_token(token: str) -> Dict[str, Any]:
    """Decode & validate Keycloak JWT."""
    print("********" + JWKS_URL)
    try:
        header = jwt.get_unverified_header(token)
        kid = header["kid"]
        public_key = get_public_key(kid)

        if not public_key:
            raise ValueError("Public key not found for Keycloak token")

        payload = jwt.decode(
            token,
            public_key,
            algorithms=[ALGO],
            audience="account",
            options={"verify_aud": True}
        )
        return payload

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}"
        )


async def get_current_user(request: Request):
    """FastAPI dependency to validate Bearer Token."""
    auth_header = request.headers.get("Authorization")

    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(401, "Missing or invalid Authorization header")

    token = auth_header.split(" ")[1]
    return verify_access_token(token)
