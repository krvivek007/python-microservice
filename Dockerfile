FROM python:3.10.0-slim-bullseye

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN adduser --disabled-password --gecos '' appuser
WORKDIR /server
RUN apt-get update && apt-get install -y curl

RUN pip install --no-cache-dir --upgrade pip poetry poetry-plugin-export
COPY wait-for-keycloak.sh /opt/wait-for-keycloak.sh
COPY pyproject.toml poetry.lock ./
RUN poetry export --without-hashes --without dev -f requirements.txt -o requirements.txt && \
        chown appuser:appuser requirements.txt && \
        pip install -r requirements.txt

USER appuser
COPY --chown=appuser:appuser start.sh /server/
COPY --chown=appuser:appuser app /server/app

RUN chmod +x /server/start.sh
ENTRYPOINT [ "/server/start.sh" ]
