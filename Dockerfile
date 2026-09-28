FROM eclipse-temurin:11-jre-noble

LABEL maintainer="anmarcel@cisco.com"

ARG GHIDRA_VERSION=9.1.2_PUBLIC_20200212
ARG TINI_VERSION=v0.19.0

ADD https://github.com{TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

RUN useradd -m ghidra && \
    mkdir -p /srv/repositories && \
    chown -R ghidra: /srv/repositories

COPY --chown=ghidra:ghidra launch.sh.patch /tmp/
WORKDIR /opt

RUN apt-get update && apt-get install -y unzip wget gettext-base patch python3 python3-pip && \
    wget -q -O ghidra.zip https://github.com && \
    unzip ghidra.zip && \
    rm ghidra.zip && \
    ln -s ghidra_9.1.2_PUBLIC ghidra && \
    cd ghidra && \
    patch -p0 < /tmp/launch.sh.patch && \
    rm -rf docs && \
    cd .. && \
    chown -R ghidra: ghidra*

WORKDIR /app
COPY --chown=ghidra:ghidra . /app
RUN pip3 install --no-cache-dir -r requirements.txt

USER ghidra
VOLUME /srv/repositories

ENV ghidra_home=/opt/ghidra
EXPOSE 8080

CMD ["gunicorn", "-w", "2", "-t", "300", "-b", "0.0.0.0:8080", "flask_api:app"]
