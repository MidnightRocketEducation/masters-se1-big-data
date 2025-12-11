FROM docker.io/debian:trixie
LABEL org.opencontainers.image.description="This image serves as an init container which fetches and extracts the yelp dataset."

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
	export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
	&& apt-get -q update \
	&& apt-get -q full-upgrade -y \
	&& apt-get -q --no-install-recommends install -y \
		unzip \
		jq \
		ca-certificates \
		curl

COPY fetch /fetch

VOLUME ["/output", "/tmp"]

ENV OUTPUT_DIR="/output"

ENTRYPOINT ["/fetch"]
