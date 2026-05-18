FROM python:3.12-slim

WORKDIR /app


RUN pip install --no-cache-dir poetry==2.4.1


COPY pyproject.toml poetry.lock ./
RUN poetry config virtualenvs.create false \
 && poetry install --only main --no-root


RUN adduser --system --no-create-home --group appuser

COPY app.py ./ # too many COPY -> could have done it in command
COPY templates ./templates

RUN chown -R appuser:appuser /app

USER appuser

ENV PORT=5000 \ # why not pass it as ARGS first ?
    VERSION=1.0.0

EXPOSE 5000

CMD ["python", "app.py"]
