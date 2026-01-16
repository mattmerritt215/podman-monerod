FROM debian:bookworm-slim AS builder

ARG MONERO_VERSION=0.18.4.5
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg dirmngr bzip2 xz-utils \
    build-essential binutils cmake pkg-config \
    libboost-all-dev libssl-dev libzmq3-dev libunbound-dev libsodium-dev \
    libunwind8-dev liblzma-dev libreadline-dev libldns-dev libexpat1-dev \
    libpgm-dev libhidapi-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN set -eux; \
    curl -fsSLo /tmp/binaryfate.asc \
        https://raw.githubusercontent.com/monero-project/monero/master/utils/gpg_keys/binaryfate.asc; \
    gpg --batch --show-keys --with-colons --fingerprint /tmp/binaryfate.asc \
        | grep -q 'fpr:::::::::81AC591FE9C4B65C5806AFC3F0AF4D462A0BDF92:'; \
    export GNUPGHOME=/tmp/gnupg; mkdir -m 0700 "$GNUPGHOME"; \
    gpg --batch --import /tmp/binaryfate.asc; \
    curl -fsSLo /tmp/hashes.txt https://www.getmonero.org/downloads/hashes.txt; \
    gpg --batch --verify /tmp/hashes.txt; \
    TARBALL="monero-source-v${MONERO_VERSION}.tar.bz2"; \
    curl -fsSLo "/tmp/${TARBALL}" "https://downloads.getmonero.org/cli/${TARBALL}"; \
    EXPECTED="$(grep " ${TARBALL}$" /tmp/hashes.txt | awk '{print $1}')"; \
    test -n "$EXPECTED"; \
    echo "${EXPECTED} /tmp/${TARBALL}" | sha256sum -c ; \
    tar -xjf "/tmp/${TARBALL}" -C /src; \
    MONERO_DIR="$(find /src -maxdepth 1 -type d -name 'monero*' | head -n1)"; \
    cd "$MONERO_DIR"; \
    make -j"$(nproc)" release; \
    strip build/release/bin/monerod; \
    mkdir -p /out/usr/local/bin; \
    cp build/release/bin/monerod /out/usr/local/bin/monerod; \
    ldd /out/use/local/bin/monerod \
        | awk '$1 ~ /^\// {print $1} $3 ~ /^\// {print $3}' \
        | sort -u \
        | xargs -r -I{} cp --parents -v {} /out

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /out/ /
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod 0755 /usr/local/bin/entrypoint.sh \
    && useradd --system --uid 10001 --create-home --home-dir /data --shell /usr/bin/nologin monero \
    && mkdir -p /data \
    && chown -R monero:monero /data

VOLUME ["/data"]

EXPOSE 18080 18081 18089

USER monero
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]