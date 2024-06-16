#!/usr/bin/env bash
####################
set -e
####################
readonly COMMIT_V="26f296f76fb4308904c25f3a7d30a48428fffd1c"
####################
build() {
	mkdir -p /tmp/build
	cd /tmp/build
	wget -O rustup.sh https://sh.rustup.rs
	chmod +x rustup.sh
	./rustup.sh -y
	source ${HOME}/.cargo/env
	git clone https://github.com/scsibug/nostr-rs-relay
	cd nostr-rs-relay
	git checkout ${COMMIT_V}
	cargo build --release
	mkdir -p /usr/src/app
	mv target/release/nostr-rs-relay /usr/src/app/nostr-rs-relay
	cd /
	rm -rf ~/.cargo
	rm -rf /tmp/build
}
####################
build
