FROM python:3.12-alpine

WORKDIR /app
COPY server.py .

RUN mkdir -p /data && chown nobody:nobody /data
VOLUME /data

EXPOSE 8081
USER nobody

CMD ["python", "-u", "server.py"]
