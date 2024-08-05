FROM python:3.11.1-slim as python-base

ARG GITLAB_USER
ARG GITLAB_TOKEN
ARG VERSION

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    POETRY_VERSION=1.5.1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    VERSION=$VERSION

ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

RUN apt-get update &&\
    apt-get install wget tar xz-utils -y &&\
    cd /opt &&\
    wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz &&\
    tar -xf ffmpeg-release-amd64-static.tar.xz &&\
    rm ffmpeg-release-amd64-static.tar.xz &&\
    ln -s /opt/ffmpeg-6.1-amd64-static/ff* /usr/bin

# Install media info
RUN apt-get install git automake autoconf libtool pkg-config make g++ zlib1g-dev libcurl4-openssl-dev  -y &&\
    cd /tmp &&\
    wget https://mediaarea.net/download/binary/mediainfo/23.11/MediaInfo_CLI_23.11_GNU_FromSource.tar.gz &&\
    tar -xf MediaInfo_CLI_23.11_GNU_FromSource.tar.gz &&\
    rm MediaInfo_CLI_23.11_GNU_FromSource.tar.gz &&\
    cd MediaInfo_CLI_GNU_FromSource &&\
    ./CLI_Compile.sh --with-libcurl &&\
    cd MediaInfo/Project/GNU/CLI &&\
    make install &&\
    rm -rf MediaInfo_CLI_GNU_FromSource &&\
    apt-get remove git automake autoconf libtool pkg-config make g++ zlib1g-dev libcurl4-openssl-dev -y

# builder-base is used to build dependencies
FROM python-base as builder-base

WORKDIR /app
COPY ./poetry.lock poetry.lock
COPY ./pyproject.toml pyproject.toml

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        curl=7.74.0-1.3* \
        build-essential=12.9 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir poetry=="${POETRY_VERSION}" \
    && poetry config http-basic.oxolo "${GITLAB_USER}" "${GITLAB_TOKEN}" \
    && poetry install


COPY . .
