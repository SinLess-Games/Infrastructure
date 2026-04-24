FROM python:3.12-alpine AS builder

WORKDIR /src

COPY Docs/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

COPY mkdocs.yml /src/mkdocs.yml
COPY Docs /src/Docs

RUN mkdocs build --clean --strict

FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY Docs/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /src/site /usr/share/nginx/html
