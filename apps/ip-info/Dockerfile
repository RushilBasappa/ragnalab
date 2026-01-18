FROM python:3.12-alpine

RUN apk add --no-cache iproute2

WORKDIR /app
COPY server.py .

EXPOSE 3099

CMD ["python3", "server.py"]
