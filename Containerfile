FROM docker.io/library/debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN \
	set -e; \
	apt update; \
	apt install -y --no-install-recommends \
		wget git ca-certificates gcc libc-dev make protobuf-compiler

COPY volume/scripts/build.sh /scripts/build.sh

RUN \
	/scripts/build.sh

FROM docker.io/library/debian:bookworm-slim

COPY --from=0 /usr/src/app/nostr-rs-relay /usr/src/app/nostr-rs-relay

ENV RUST_LOG=info,nostr_rs_relay=info

WORKDIR /usr/src/app

ENTRYPOINT ["/usr/src/app/nostr-rs-relay", "--db", "/usr/src/app/db"]
