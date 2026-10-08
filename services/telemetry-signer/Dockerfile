FROM python:3.12-slim

WORKDIR /app

COPY pyproject.toml ./
COPY src ./src
RUN pip install --no-cache-dir . \
    && useradd --uid 10001 --no-create-home signer

USER 10001

ENV PORT=8080
EXPOSE 8080

CMD ["sh", "-c", "uvicorn telemetry_signer.app:app --host 0.0.0.0 --port ${PORT}"]
