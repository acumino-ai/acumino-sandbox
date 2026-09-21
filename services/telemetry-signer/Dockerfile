FROM python:3.12

WORKDIR /app

COPY pyproject.toml ./
COPY src ./src
RUN pip install .

ENV PORT=8080
EXPOSE 8080

CMD ["sh", "-c", "uvicorn telemetry_signer.app:app --host 0.0.0.0 --port ${PORT}"]
