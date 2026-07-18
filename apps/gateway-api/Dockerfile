FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY apps/gateway-api/requirements.txt /tmp/gateway-requirements.txt
RUN pip install --no-cache-dir -r /tmp/gateway-requirements.txt

COPY apps/gateway-api/app ./app
COPY packages/animation-validation ./packages/animation-validation
COPY configs/animation ./configs/animation

ENV PYTHONPATH=/app/packages/animation-validation

EXPOSE 8100

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8100"]
