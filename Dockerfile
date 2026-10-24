# Полная сборка с нуля — для docker build / docker compose без CI
FROM python:3.11-slim-bookworm@sha256:0a310eeecf4e1f5a0743f9a6520c90c88d089c903ca5fd283f501e3a805f5f89 AS base

FROM base AS build
ENV SOURCE_DATE_EPOCH=1704067200

SHELL [ "/bin/sh", "-eu", "-c" ]
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
RUN pip install --no-cache-dir 'poetry==2.5.1' 'poetry-plugin-export==1.10.0'

WORKDIR /build
COPY pyproject.toml poetry.lock README.md ./
COPY src/ src/
RUN \
  mkdir -p dist \
  && poetry export --without-hashes --format constraints.txt --output dist/constraints.txt \
  && pip wheel --no-cache-dir --isolated --requirement dist/constraints.txt --wheel-dir dist/vendor \
  && poetry build --format wheel


FROM base AS final

COPY --from=build /build/dist/ /tmp/dist/
RUN pip install --no-cache-dir --no-compile --no-index --find-links /tmp/dist/vendor /tmp/dist/*.whl \
 && rm -rf /tmp/dist

ENV HOST="0.0.0.0"
ENV PORT="8080"
USER nobody
EXPOSE ${PORT}/tcp
ENTRYPOINT [ "server" ]