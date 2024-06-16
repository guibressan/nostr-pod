#!/usr/bin/env bash
####################
set -e
####################
readonly RELDIR="$(dirname ${0})"
readonly HELP_MSG="usage: <build | up | down | clean | mk-systemd | rm-systemd | help>"
readonly IMG_NAME="nostr-relay"
readonly CT_NAME="nostr-relay"
####################
eprintln() {
	! [ -z "${1}" ] || eprintln 'eprintln: undefined message'
	printf "${1}\n" 1>&2
	return 1
}
check_env() {
	[ -e "${RELDIR}/.env" ] || eprintln 'please, copy .env.example to .env'
	[ -e "${RELDIR}/config.toml" ] \
		|| eprintln 'please, copy config.toml.example to config.toml'
	source "${RELDIR}"/.env
	! [ -z "${EXT_PORT}" ] || eprintln 'undefined env EXT_PORT'
}
common() {
	mkdir -p "${RELDIR}/volume/data/db"
	chmod +x "${RELDIR}"/volume/scripts/*.sh
	check_env
}
mk_systemd() {
	! [ -e "/etc/systemd/system/${CT_NAME}.service" ] \
	|| eprintln "service ${CT_NAME} already exists"
	local user="${USER}"
	sudo bash -c "cat << EOF > /etc/systemd/system/${CT_NAME}.service
[Unit]
Description=Nostr Relay Pod
After=network.target

[Service]
Environment=\"PATH=/usr/local/bin:/usr/bin:/bin:${PATH}\"
User=${user}
Type=forking
ExecStart=/bin/bash -c \"cd ${PWD}/${RELDIR}; ./control.sh up\"
ExecStop=/bin/bash -c \"cd ${PWD}/${RELDIR}; ./control.sh down\"
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
"
	sudo systemctl enable "${CT_NAME}".service
}
rm_systemd() {
	[ -e "/etc/systemd/system/${CT_NAME}.service" ] || return 0
	sudo systemctl stop "${CT_NAME}".service || true
	sudo systemctl disable "${CT_NAME}".service
	sudo rm /etc/systemd/system/"${CT_NAME}".service
}
build() {
	podman build \
	-f "${RELDIR}/Containerfile" \
	--tag "${IMG_NAME}" \
	"${RELDIR}"
}
up() {
	podman run --rm \
		-p ${EXT_PORT}:8080 \
		-v ${RELDIR}/volume:/app \
		-v ${RELDIR}/volume/data/db:/usr/src/app/db:Z \
		-v ${RELDIR}/config.toml:/usr/src/app/config.toml:ro,Z \
		--name "${CT_NAME}" \
		"localhost/${IMG_NAME}" 2>&1 | tee -a ${RELDIR}/volume/data/rl.log &
}
down() {
	podman stop "${IMG_NAME}" || true
}
clean() {
	printf "Are you sure you want to delete the data? (Y/n): "
	read v
	[ "${v}" == "Y" ] || eprintln 'ABORT'
	rm -rf "${RELDIR}/volume/data"
}
####################
common
####################
case ${1} in
	build) build ;;
	up) up ;;
	down) down ;;
	clean) clean ;;
	mk-systemd) mk_systemd ;;
	rm-systemd) rm_systemd ;;
	*) eprintln "${HELP_MSG}" ;;
esac

