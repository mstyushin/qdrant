FROM rust:1.60.0 as builder

RUN apt-get update ; apt-get install -y clang cmake ; rustup component add rustfmt

COPY . ./qdrant
WORKDIR ./qdrant

# Build actual target here
RUN cargo build --release --bin qdrant

FROM debian:11-slim
RUN groupadd -r qdrant --gid=999; useradd -r -g qdrant --uid=999 --home-dir=/qdrant --shell=/bin/bash qdrant

RUN apt-get update; \
    apt-get install -y --no-install-recommends tzdata curl

# grab gosu for easy step-down from root
# https://github.com/tianon/gosu/releases
ENV GOSU_VERSION 1.14
RUN set -eux; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends ca-certificates dirmngr gnupg wget; \
	rm -rf /var/lib/apt/lists/*; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*; \
	chmod +x /usr/local/bin/gosu; \
	gosu --version; \
	gosu nobody true

ENV TZ=Etc/UTC \
    RUN_MODE=production

COPY --from=builder /qdrant/target/release/qdrant /qdrant/qdrant
COPY --from=builder /qdrant/config /qdrant/config

RUN ln -s /qdrant/qdrant /usr/bin/qdrant

RUN mkdir -p /qdrant/storage/collections /qdrant/storage/aliases; \
    chown -R qdrant:qdrant /qdrant; \
    chmod -R 777 /qdrant; \
    mkdir /init.d; \
    chown -R qdrant:qdrant /init.d

VOLUME /qdrant/storage
WORKDIR /qdrant

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 6333
EXPOSE 6334
CMD ["qdrant"]
