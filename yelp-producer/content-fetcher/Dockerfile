FROM docker.io/debian:trixie

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
	export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
	&& apt-get -q update \
	&& apt-get -q full-upgrade -y \
	&& apt-get -q --no-install-recommends install -y \
		unzip \
		curl

COPY fetch /fetch

VOLUME ["/output", "/tmp"]

ENV OUTPUT_DIR="/output"

ENTRYPOINT ["/fetch"]
